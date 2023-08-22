//
//  PlayerViewModel.swift
//  Music Player X
//
//  Created by Richard Pacheco on 7/5/23.
//

import SwiftUI
import AVFoundation
import Combine
import MediaPlayer

class PlayerViewModel: NSObject, ObservableObject {
    static var shared = PlayerViewModel()

    // MARK: - Public properties
    @Published var showPlayerFullScreen: Bool = false
    @Published var showQueueView: Bool = false
    @Published var tracks: [Track] = {
        guard let track1URL = Bundle.main.url(forResource: "ariana-grande_no-tears-left-to-cry", withExtension: "mp3"),
              let track2URL = Bundle.main.url(forResource: "5-seconds-of-summer-teeth-live_teeth", withExtension: "mp3"),
              let track3URL = Bundle.main.url(forResource: "anja-nissen_where-i-am", withExtension: "mp3"),
              let track4URL = Bundle.main.url(forResource: "demi-lovato_tell-me-you-love-me", withExtension: "mp3"),
              let track5URL = Bundle.main.url(forResource: "loreen-tattoo", withExtension: "mp3")
        else { return [] }
        return [
            Track(
                name: "No Tears Left To Cry",
                album: "No Tears Left To Cry",
                cover: "no-tears-left-to-cry",
                artist: Artist(
                    name: "Ariana Grande",
                    image: "ariana-grande",
                    tracks: []
                ),
                url: track1URL
            ),
            Track(
                name: "Teeth",
                album: "End Summer",
                cover: "5-seconds-of-the-summer",
                artist: Artist(
                    name: "5 Seconds Of The Summer",
                    image: "5-seconds-of-the-summer",
                    tracks: []
                ),
                url: track2URL
            ),
            Track(
                name: "Where I Am",
                album: "Eurovision",
                cover: "where-i-am",
                artist: Artist(
                    name: "Anja Nissen",
                    image: "where-i-am",
                    tracks: []
                ),
                url: track3URL
            ),
            Track(
                name: "Tell Me You Love Me",
                album: "Tell Me You Love Me",
                cover: "tell-me-you-love-me",
                artist: Artist(
                    name: "Ariana Grande",
                    image: "ariana-grande",
                    tracks: []
                ),
                url: track4URL
            ),
            Track(
                name: "Tatto",
                album: "Eurovision",
                cover: "tatto",
                artist: Artist(
                    name: "Loreen",
                    image: "tatto",
                    tracks: []
                ),
                url: track5URL
            ),
        ]
    }()
    @Published var currentTrackIndex = 0
    @Published var offset : CGFloat = 0
    @Published var height = UIScreen.main.bounds.height / 3

    // MARK: - Playing status
    @Published var isPlaying: Bool = false
    @Published var playerProgress: Double = 0.0
    @Published var timeReproduced: String?
    @Published var trackDuration: String = "0:00"

    // MARK: - Buttons status
    @Published var backwardButtonIsDisabled: Bool = false
    @Published var forwarButtonIsDisabled: Bool = false
    @Published var repeatState: Bool = false {
        didSet {
            validateForwardButtonState()
            validateBackwardButtonState()
        }
    }
    @Published var shuffleState: Bool = false

    // MARK: - Track info for UI
    @Published var trackId: UUID = UUID()
    @Published var trackName: String = ""
    @Published var trackAlbum: String = ""
    @Published var trackCover: String = ""
    @Published var trackArtists: String = ""


    // MARK: - Private properties
    private var cancellables = Set<AnyCancellable>()
    private var totalDuration: Double = 0.0
    private var likeOperationInFlight: Bool = false
    private var tracksInOrderBeforeShuffle: [Track] = []

    private var timeObserverToken: Any?
    private var updateReproducedTimeWithTimer: Bool = true
    private var queuePlayer = AVQueuePlayer() {
        willSet {
            if let timeObserverToken = timeObserverToken {
                queuePlayer.removeTimeObserver(timeObserverToken)
                self.timeObserverToken = nil
            }

            let interval = CMTime(value: 1, timescale: 2)
            timeObserverToken = newValue.addPeriodicTimeObserver(forInterval: interval,
                                                                    queue: .main) { [unowned self] _ in
                self.updateQueueTimeAndProgress()
            }
        }
    }

    // MARK: - Constructors
    override init() {
        super.init()
        configureAirplayEnviroment()
        setupRemoteTransportControls()
        configureListeners()
        loadQueuePlayerItems()
//        prependToQueue(track: tracks.first)
    }

    private func configureListeners() {
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(playerDidFinishPlaying),
                         name: .AVPlayerItemDidPlayToEndTime,
                         object: nil
            )
    }

    @objc func playerDidFinishPlaying() {
        queuePlayer.advanceToNextItem()
        if queuePlayer.items().isEmpty {
            currentTrackIndex = 0

            if repeatState {
                loadQueuePlayerItems()
            } else {
                let nextElements: [Track] = Array(tracks[currentTrackIndex..<tracks.count])
                let playerItems = nextElements.map { AVPlayerItem(asset: AVURLAsset(url: $0.url!))}

                queuePlayer = AVQueuePlayer(items: playerItems)
                updateUIElements(isPlaying: false)
            }
        } else {
            currentTrackIndex += currentTrackIndex < tracks.count ? 1 : 0
            updateUIElements(isPlaying: isPlaying)
        }
    }

    private func configureAirplayEnviroment() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback,
                                         mode: .default,
                                         policy: .longFormAudio,
                                         options: [.allowAirPlay])
            UIApplication.shared.beginReceivingRemoteControlEvents()
        } catch {
            print(" \(#file) \(#function) \(#line): \(error)")
        }
    }

    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self else {return .commandFailed}
            let playerRate = self.queuePlayer.rate
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                self.queuePlayer.seek(to: CMTime(seconds: event.positionTime, preferredTimescale: CMTimeScale(1000)), completionHandler: { [weak self](success) in
                    guard let self = self else {return}
                    if success {
                        self.queuePlayer.rate = playerRate
                    }
                })
                return .success
            }

            return .commandFailed
        }

        commandCenter.playCommand.addTarget { [unowned self] event in
            self.play()
            updateQueueTimeAndProgress()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [unowned self] event in
            self.pause()
            updateQueueTimeAndProgress()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            self.didTapBackward()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            if !tracks.isEmpty, currentTrackIndex < tracks.count - 1 {
                self.didTapForward()
                return .success
            }

            return .commandFailed
        }
    }

    private func setupNotificationView() {
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = self.trackName
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = self.trackAlbum
        nowPlayingInfo[MPMediaItemPropertyArtist] = self.trackArtists
        let image = UIImage(named: self.trackCover) ?? UIImage()
        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { size in
            return image
        })
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    // MARK: - Queue control
    private func initQueuePlaylist(tracks : [Track]? = nil) {
        if let strongTracks = tracks {
            self.tracks = strongTracks
        } else {
            return
        }
        updateCurrentItem(index: currentTrackIndex)
    }

    func prependToQueue(tracks: [Track]? = nil, track: Track? = nil, initReproduction: Bool = true) {
        var newTracks: [Track] = self.tracks
        if let t = tracks {
            newTracks.insert(contentsOf: t, at: currentTrackIndex)
        } else if let t = track {
            if t.id == trackId {
                playTrack()
                return
            } else {
                newTracks.insert(contentsOf: [t], at: currentTrackIndex)
            }
        } else {
            return
        }

        self.tracks = newTracks
        loadQueuePlayerItems()
    }

    func addToQueue(tracksToAdd: [Track], isPlayNext: Bool) {

        if tracks.count == 0 {
            if tracksToAdd.count > 1 {
                prependToQueue(tracks: tracksToAdd)
            } else {
                prependToQueue(track: tracksToAdd[0])
            }
            return
        }

        tracksToAdd
            .filter { $0.url != nil }
            .enumerated()
            .forEach { index, track in
                let item = AVPlayerItem(asset: AVURLAsset(url: track.url!))
                let after = isPlayNext ? queuePlayer.currentItem : queuePlayer.items().last
                if queuePlayer.canInsert(item, after: after) {
                    queuePlayer.insert(item, after: after)
                    tracks.insert(track, at: isPlayNext ? currentTrackIndex + index + 1: tracks.count )
                }
            }

        validateForwardButtonState()
        validateBackwardButtonState()
    }

    func addToQueue(tracksToAdd: Track..., isPlayNext: Bool) {
        addToQueue(tracksToAdd: tracksToAdd, isPlayNext: isPlayNext)
    }

    func replaceQueue(with tracks: [Track]) {
        currentTrackIndex = 0
        self.tracks = []
        prependToQueue(tracks: tracks)
    }

    private func loadQueuePlayerItems(items: [AVPlayerItem]? = nil) {
        if let items = items {
            queuePlayer = AVQueuePlayer(items: items)
        } else {
            let nextElements: [Track] = Array(tracks[currentTrackIndex..<tracks.count])
            let playerItems = nextElements.map { AVPlayerItem(asset: AVURLAsset(url: $0.url!))}

            queuePlayer = AVQueuePlayer(items: playerItems)
        }
        startPlayingFirstTrackOfQueue()
    }

    private func startPlayingFirstTrackOfQueue() {
        playTrack()
        updateUIElements(isPlaying: true)
    }

    // MARK: - OJO, revisar
    func reproduceSpecificAudioTrackOfQueue(_ track: Track?) {
        guard let track = track else {return}
        let index = tracks.firstIndex(where: {$0.id == track.id})
        updateCurrentItem(index: index)
    }

    func reproduceSpecificTrackOfQueue(_ track: Track) {
        let index = tracks.firstIndex(where: {$0.id == track.id}) ?? 0
        if index != currentTrackIndex {
            currentTrackIndex = index
            let nextElements: [Track] = Array(tracks[currentTrackIndex..<tracks.count])
            initQueueWithElements(elements: nextElements)
        }
    }

    func initQueueWithElements(elements: [Track]) {
        let playerItems = elements.map { AVPlayerItem(asset: AVURLAsset(url: $0.url ?? URL(fileURLWithPath: "")))}

        queuePlayer = AVQueuePlayer(items: playerItems)
        startPlayingFirstTrackOfQueue()
    }

    private func updateCurrentItem(index: Int?) {
        validateAuthorizationPlayback()
    }

    func clearQueue() {
        guard let currentTrack = tracks[safe: currentTrackIndex],
              let currentItem = queuePlayer.currentItem
        else {return}
        tracks = [currentTrack]
        var itemsToRemove: [AVPlayerItem] = []
        queuePlayer.items().forEach { item in
            if !(currentItem == item) {
                itemsToRemove.append(item)
            }
        }
        itemsToRemove.forEach { item in
            queuePlayer.remove(item)
        }

        currentTrackIndex = 0
    }

    func removeItem(_ track: Track) {
        tracks.removeAll(where: {$0.id == track.id})
        var itemsToRemove: [AVPlayerItem] = []
        queuePlayer.items().forEach { item in
            if (track.url?.absoluteString == (item.asset as? AVURLAsset)?.url.absoluteString) {
                itemsToRemove.append(item)
            }
        }
        itemsToRemove.forEach { item in
            if let currentItem = queuePlayer.currentItem, currentItem == item {
                queuePlayer.advanceToNextItem()
            } else {
                queuePlayer.remove(item)
            }
        }
        if tracks.count == 0 {
            pause()
        }
    }

    func resetAudioPlayerQueue() {
        tracks = []
        tracksInOrderBeforeShuffle = []
    }

    // MARK: - Player control functions
    func playOrPause() {
        if queuePlayer.timeControlStatus == .playing {
            pause()
        }else{
            play()
        }
    }

    func pauseAudioPlayer() {
        pause()
    }

    private func validateAuthorizationPlayback() {
        play()
        updateTrackDetails()
        setupNotificationView()
    }

    private func play() {
        queuePlayer.play()
        updateUIElements(isPlaying: true)
    }

    private func pause() {
        queuePlayer.pause()
        updateUIElements(isPlaying: false)
    }

    func didTapForward() {
        if !tracks.isEmpty, currentTrackIndex < tracks.count - 1 {
            currentTrackIndex += 1
            self.queuePlayer.advanceToNextItem()
            self.updateUIElements()
        } else if currentTrackIndex == tracks.count - 1 && repeatState {
            currentTrackIndex = 0
            loadQueuePlayerItems()
        }
    }

    func didTapBackward() {
        if currentTrackIndex - 1 < 0 && !repeatState {
            currentTrackIndex = 0
        } else if currentTrackIndex - 1 < 0 && repeatState {
            currentTrackIndex = tracks.count - 1
        } else {
            currentTrackIndex -= 1
        }

        let previousAsset = AVURLAsset(url: tracks[currentTrackIndex].url!)
        var currentAsset: AVURLAsset?

        if (currentTrackIndex + 1 >= tracks.count) {
            currentAsset = AVURLAsset(url: tracks[currentTrackIndex].url!)
        } else {
            currentAsset = AVURLAsset(url: tracks[currentTrackIndex + 1].url!)
        }

        guard let currentAsset = currentAsset else {return}

        let previousItem = AVPlayerItem(asset: previousAsset)
        let currentItem = AVPlayerItem(asset: currentAsset)

        queuePlayer.replaceCurrentItem(with: previousItem)
        if queuePlayer.canInsert(currentItem, after: previousItem) {
            queuePlayer.insert(currentItem, after: previousItem)
        }
        self.updateUIElements()
    }

    private func playTrack() {
        if !tracks.isEmpty, let _ = tracks[safe: currentTrackIndex]?.url {
            validateAuthorizationPlayback()
        }
    }

    func doShuffleQueue() {
//        guard let currentItem = queuePlayer.currentItem else {return}
//        removeAllItemsExceptCurrent(currentItem: currentItem)
//        if shuffleState {
//            tracks = tracksInOrderBeforeShuffle
//            currentTrackIndex = tracksInOrderBeforeShuffle.firstIndex(where: { $0.id == trackId }) ?? 0
//            tracksInOrderBeforeShuffle = []
//            shuffleState = false
//            let tracksToReproduce = Array(tracks[(currentTrackIndex + 1)..<tracks.count])
//            insertItemsInQueue(currentItem: currentItem, items: tracksToReproduce)
//        } else {
//            let trackToPlaceFirst = tracks[currentTrackIndex]
//            tracksInOrderBeforeShuffle = tracks
//            tracks.shuffle()
//            shuffleState = true
//            guard let newIndexOfCurrentTrack = tracks.firstIndex(where: { $0.id == trackToPlaceFirst.id }) else {return}
//            tracks.move(fromOffsets: IndexSet(integer: newIndexOfCurrentTrack), toOffset: 0)
//            currentTrackIndex = 0
//            let tracksToReproduce = tracks.filter({ $0.id != trackToPlaceFirst.id })
//            insertItemsInQueue(currentItem: currentItem, items: tracksToReproduce)
//        }
    }

    private func removeAllItemsExceptCurrent(currentItem: AVPlayerItem) {
        var itemsToRemove: [AVPlayerItem] = []
        queuePlayer.items().forEach { item in
            if !(currentItem == item) {
                itemsToRemove.append(item)
            }
        }
        itemsToRemove.forEach { item in
            queuePlayer.remove(item)
        }
    }

    private func insertItemsInQueue(currentItem: AVPlayerItem, items: [Track]) {
        let playerItems = items.map { AVPlayerItem(asset: AVURLAsset(url: $0.url ?? URL(fileURLWithPath: "")))}
        queuePlayer.items().forEach { item in
            if currentItem != item {
                queuePlayer.remove(item)
            }
        }
        var itemBeforeItemToPlace = currentItem
        playerItems.forEach { newItem in
            queuePlayer.insert(newItem, after: itemBeforeItemToPlace)
            itemBeforeItemToPlace = newItem
        }
    }

    func repeatAction() {
        repeatState.toggle()
    }

    func goToSpecificTime(percentage: Float64) {

        guard let durationTime = queuePlayer.currentItem?.duration else { return }

        // Percentage of duration
        let percentageTime = CMTimeMultiplyByFloat64(durationTime, multiplier: percentage)

        guard percentageTime.isValid && percentageTime.isNumeric else { return }

        // Percentage plust current time
        var targetTime = percentageTime
        targetTime = targetTime.convertScale(durationTime.timescale, method: .default)

        // Sanity checks
        guard targetTime.isValid && targetTime.isNumeric else { return }

        if targetTime > durationTime {
            targetTime = durationTime // seek to end
        }

        queuePlayer.seek(to: targetTime)
    }

    // MARK: - UI Animation
    func onchanged(value: DragGesture.Value){
        let value = value.translation.height
        guard showPlayerFullScreen, value >= 0 else {return}
        offset = value
    }

    func onended(value: DragGesture.Value){
        withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.95, blendDuration: 0.95)){
            if value.translation.height > height{
                showPlayerFullScreen = false
            }
            offset = 0
        }
    }

    func dismissView() {
        withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.95, blendDuration: 0.95)){
            showPlayerFullScreen = false
            offset = 0
        }
    }

    func showFullScreen() {
        if !showPlayerFullScreen {
            withAnimation(.spring()){showPlayerFullScreen = true}
        }
    }

    func updateTimeWithProgress(_ value: Double) {
        guard let playerItem = queuePlayer.currentItem else {return}

        let duration = playerItem.duration.seconds * value
        timeReproduced = formatted(time: duration)
    }

    // MARK: - UI Update functions
    private func updateUIElements(isPlaying: Bool? = nil) {
        updateQueueTimeAndProgress()
        updateTrackDetails()
        setupNotificationView()
        validateBackwardButtonState()
        validateForwardButtonState()
        if let isPlaying = isPlaying {
            updateIsPlayingWithAnimation(isPlaying)
        }
    }

    func updateQueueTimeAndProgress() {
        guard let playerItem = queuePlayer.currentItem else {return}

        let duration = playerItem.duration.seconds
        let progress = playerItem.currentTime().seconds

        playerProgress = ((progress * 100) / (!duration.isNaN ? duration : 1)) / 100
        if updateReproducedTimeWithTimer {
            timeReproduced = formatted(time: progress)
        }

        if totalDuration != duration, !duration.isNaN {
            totalDuration = duration
            trackDuration = formatted(time: duration)
        } else if duration.isNaN {
            trackDuration = tracks[currentTrackIndex].durationString ?? "00:00"
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = duration
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = progress

    }

    func updateTrackDetails() {
        let item = tracks[safe: currentTrackIndex]
        trackId = item?.id ?? UUID()
        trackName = item?.name ?? ""
        trackAlbum = item?.album ?? ""
        trackArtists = item?.artist.name ?? ""
        trackCover = item?.cover ?? ""
    }

    private func validateForwardButtonState() {
        MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = currentTrackIndex < tracks.count - 1 && !repeatState
        forwarButtonIsDisabled = currentTrackIndex == tracks.count - 1 && !repeatState
    }

    private func validateBackwardButtonState() {
        MPRemoteCommandCenter.shared().previousTrackCommand.isEnabled = currentTrackIndex > 0 && !repeatState
        backwardButtonIsDisabled = currentTrackIndex == 0 && !repeatState
    }

    private func updateIsPlayingWithAnimation(_ newValue: Bool) {
        withAnimation(.spring()) {
            isPlaying = newValue
        }
    }

    func moveTrack(from source: IndexSet, to destination: Int) {

        let initPosition = (source.first?.asInt ?? 0)
        let endlPosition = (source.first?.asInt ?? 0) < destination ? destination - 1 : destination

        tracks.move(fromOffsets: source, toOffset: destination)

        if initPosition == currentTrackIndex {
            currentTrackIndex = endlPosition
        } else {
            currentTrackIndex = (source.first?.asInt ?? 0) < destination ? currentTrackIndex - 1 : currentTrackIndex + 1
        }

        let tracksToReproduce = Array(tracks[(currentTrackIndex + 1)..<tracks.count])
        guard let currentItem = queuePlayer.currentItem else {return}

        removeAllItemsExceptCurrent(currentItem: currentItem)
        insertItemsInQueue(currentItem: currentItem, items: tracksToReproduce)
        updateUIElements(isPlaying: isPlaying)
    }

    private func playSignedTrack() {
        play()
        updateTrackDetails()
        setupNotificationView()
    }

    func useTimerToReproducedTime(_ value: Bool) {
        updateReproducedTimeWithTimer = value
    }
}

extension PlayerViewModel {
    func formatted(time: Double) -> String {
        var seconds = Int(ceil(time))
        var hours = 0
        var mins = 0

        if seconds > TimeConstant.secsPerHour {
            hours = seconds / TimeConstant.secsPerHour
            seconds -= hours * TimeConstant.secsPerHour
        }

        if seconds > TimeConstant.secsPerMin {
            mins = seconds / TimeConstant.secsPerMin
            seconds -= mins * TimeConstant.secsPerMin
        }

        var formattedString = ""
        if hours > 0 {
            formattedString = "\(String(format: "%02d", hours)):"
        }
        formattedString += "\(String(format: "%02d", mins)):\(String(format: "%02d", seconds))"
        return formattedString
    }
}

