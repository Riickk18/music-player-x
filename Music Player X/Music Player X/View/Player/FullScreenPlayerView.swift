//
//  FullScreenPlayerView.swift
//  Music Player X
//
//  Created by Richard Pacheco on 7/4/23.
//

import SwiftUI

struct FullScreenPlayerView: View {
    @StateObject var viewModel = PlayerViewModel.shared
    var namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                .frame(width: 50, height: 7)
                .foregroundColor(.black.opacity(0.3))
                .onTapGesture {
                    viewModel.dismissView()
                }

            Spacer()

            VStack {
                Spacer()
                Image("cover1")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
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
                    ProgressSliderView(allowDragGesture: .constant(true), progressValue: $viewModel.playerProgress, widthOfParent: proxy.size.width)
                }

                Spacer()

                HStack(spacing: 30) {
                    Button {
                        print("previous")
                    } label: {
                        Image("skip-previous-icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.white)
                    }
                    .frame(width: 60)

                    Button {
                        viewModel.playOrPause()
                    } label: {
                        Image(viewModel.isPlaying ? "pause-icon" : "play-icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.white)
                    }
                    .frame(width: 60)

                    Button {
                        print("previous")
                    } label: {
                        Image("skip-next-icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.white)
                    }
                    .frame(width: 60)
                }

                Spacer()

                HStack(spacing: 20) {
                    Image(systemName: "volume.1")
                        .padding(.bottom, 5)
                    GeometryReader { proxy in
                        ProgressSliderView(allowDragGesture: .constant(true), progressValue: .constant(0.5), widthOfParent: proxy.size.width)
                    }
                    Image(systemName: "volume.3")
                        .padding(.bottom, 5)
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
                        .frame(width: 25)
                }
                .frame(width: 40, height: 40)

                Button {
                    print("airplay")
                } label: {
                    Image("airplay-icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 25)
                }
                .frame(width: 40, height: 40)

                Button {
                    print("replay")
                } label: {
                    Image("replay-icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 25)
                }
                .frame(width: 40, height: 40)
            }
            .foregroundColor(.white)

            Spacer()
        }
        .foregroundColor(.white)
        .background {
            ZStack {
                Image(viewModel.trackCover)
                VisualEffectView(effect: UIBlurEffect(style: .dark))
            }
            .ignoresSafeArea()
        }
    }
}

struct FullScreenPlayerView_Previews: PreviewProvider {
    @Namespace static var namespace
    static var previews: some View {
        FullScreenPlayerView(namespace: namespace)
    }
}
