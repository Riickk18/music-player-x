//
//  CompactPlayerView.swift
//  Music Player X
//
//  Created by Richard Pacheco on 7/4/23.
//

import SwiftUI

struct CompactPlayerView: View {
    @StateObject var viewModel = PlayerViewModel.shared
    var namespace: Namespace.ID

    var body: some View {
        HStack(spacing: 10) {
            Image(viewModel.trackCover)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .matchedGeometryEffect(id: "playerCover", in: namespace)
                .padding(7)

            VStack(alignment: .leading) {
                Text(viewModel.trackName)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(viewModel.trackArtists)
                    .font(.body)
                    .fontWeight(.regular)
            }
            .lineLimit(1)
            .foregroundColor(.white)

            Spacer()

            HStack {
                Button {
                    print("previous")
                } label: {
                    Image("skip-previous-icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.white)
                }
                .frame(width: 40)

                Button {
                    viewModel.playOrPause()
                } label: {
                    Image(viewModel.isPlaying ? "pause-icon" : "play-icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.white)
                }
                .frame(width: 40)

                Button {
                    print("previous")
                } label: {
                    Image("skip-next-icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.white)
                }
                .frame(width: 40)
            }
            .padding(7)
        }
        .frame(height: 70)
        .frame(maxWidth: .infinity)
        .background{
            ZStack {
                Image("cover1")
                VisualEffectView(effect: UIBlurEffect(style: .dark))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        .padding(.horizontal, 10)
        .onTapGesture {
            viewModel.showFullScreen()
        }
    }
}

struct CompactPlayerView_Previews: PreviewProvider {
    @Namespace static var namespace
    static var previews: some View {
        CompactPlayerView(namespace: namespace)
    }
}
