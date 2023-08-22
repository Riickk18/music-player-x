//
//  FullScreenPlayerView.swift
//  Music Player X
//
//  Created by Richard Pacheco on 7/4/23.
//

import SwiftUI

struct FullScreenPlayerView: View {
    @StateObject var viewModel = PlayerViewModel.shared
    @State private var offset = CGSize.zero
    var namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                .frame(width: 50, height: 7)
                .foregroundColor(.white.opacity(0.3))
                .padding(.top, 35)
                .onTapGesture {
                    viewModel.dismissView()
                }

            Spacer()

            VStack {
                Spacer()
                Image(viewModel.trackCover)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.85 - (viewModel.isPlaying ? 0 : 30), maxHeight: UIScreen.main.bounds.width * 0.85 - (viewModel.isPlaying ? 0 : 30))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .matchedGeometryEffect(id: "playerCover", in: namespace)
                    .padding(viewModel.isPlaying ? 0 : 30)
                Spacer()
            }
                .frame(width: UIScreen.main.bounds.width * 0.85, height: UIScreen.main.bounds.width * 0.85)
                .padding(.bottom, 30)

            VStack(spacing: 10) {
                Text(viewModel.trackName)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(viewModel.trackArtists)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .opacity(0.7)
            }
            .padding(.bottom, 30)

            VStack(spacing: 10) {
                GeometryReader { proxy in
                    ProgressSliderView(
                        allowDragGesture: .constant(true),
                        progressValue: $viewModel.playerProgress,
                        widthOfParent: proxy.size.width,
                        updateCurrentTimeWithSlider: { value in
                            viewModel.useTimerToReproducedTime(false)
                            viewModel.updateTimeWithProgress(value)
                        },
                        sliderDidSlider: { value in
                            viewModel.useTimerToReproducedTime(true)
                            viewModel.goToSpecificTime(percentage: Float64(value))
                        }
                    )
                }

                HStack(alignment: .center) {
                    Text(viewModel.timeReproduced ?? "0:00")
                    Spacer()
                    Text(viewModel.trackDuration)
                }
                .padding(.top, 20)

                Spacer()

                HStack(spacing: 30) {
                    Button {
                        viewModel.didTapBackward()
                    } label: {
                        Image("skip-previous-icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .frame(width: 70, height: 70)

                    Button {
                        viewModel.playOrPause()
                    } label: {
                        Image(viewModel.isPlaying ? "pause-icon" : "play-icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .frame(width: 70, height: 70)

                    Button {
                        viewModel.didTapForward()
                    } label: {
                        Image("skip-next-icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .frame(width: 70, height: 70)
                }

                Spacer()

                HStack(spacing: 20) {
                    Image(systemName: "volume.1")
                    GeometryReader { proxy in
                        ProgressSliderView(allowDragGesture: .constant(true), progressValue: .constant(0.5), widthOfParent: proxy.size.width)
                    }
                    .padding(.bottom, 28)
                    Image(systemName: "volume.3")
                }
            }
            .padding(.horizontal, 30)

            Spacer()

            HStack(spacing: 40) {
                Button {
                    print("cast")
                } label: {
                    Image("cast-icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30)
                }
                .frame(width: 40, height: 40)

                Button {
                    print("airplay")
                } label: {
                    Image("airplay-icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30)
                }
                .frame(width: 40, height: 40)

                Button {
                    print("replay")
                } label: {
                    Image("replay-icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30)
                }
                .frame(width: 40, height: 40)
            }

            Spacer()
        }
        .foregroundColor(.white.opacity(0.7))
        .background {
            ZStack {
                Image(viewModel.trackCover)
                    .aspectRatio(contentMode: .fill)
                VisualEffectView(effect: UIBlurEffect(style: .dark))
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .frame(maxHeight: viewModel.showPlayerFullScreen ? UIScreen.main.bounds.height : 70)
            .ignoresSafeArea()
        }
        .offset(x: 0, y: offset.height)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    print(offset.height)
                    offset = gesture.translation
                }
                .onEnded { gesture in
                    dismissOrRestoreView(with: gesture.translation)
                }
        )
    }

    private func dismissOrRestoreView(with offset: CGSize) {
        print(offset.height)
        if offset.height > 150 {
            viewModel.dismissView()
        } else {
            withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.95, blendDuration: 0.95)){
                self.offset = .zero
            }
        }
    }
}

struct FullScreenPlayerView_Previews: PreviewProvider {
    @Namespace static var namespace
    static var previews: some View {
        FullScreenPlayerView(namespace: namespace)
    }
}
