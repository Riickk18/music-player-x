//
//  PromotedArtistCellView.swift
//  Music Player X
//
//  Created by Richard Pacheco on 7/4/23.
//

import SwiftUI

struct PromotedArtistCellView: View {
    @Environment(\.colorScheme) var color
    var artist: Artist

    var body: some View {
        VStack {
            Spacer()
            Image(artist.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(Circle())
            VStack(spacing: 10) {
                Text(artist.name.uppercased())
                    .font(.title)
                    .fontWeight(.bold)
                Text("New single")
            }
            .fontDesign(.rounded)
            .frame(height: 100)
        }
        .frame(width: 250, height: 300)
        .foregroundColor(.white)
        .background {
            ZStack(alignment: .top) {
                Image(artist.image)
                    .resizable()
                VisualEffectView(effect: UIBlurEffect(style: .dark))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: (color == .light ? Color.black : Color.white).opacity(color == .light ? 0.5 : 0.25), radius: 10, x: 5, y: 5)
    }
}

struct PromotedArtistCellView_Previews: PreviewProvider {
    static var previews: some View {
        PromotedArtistCellView(artist: Artist(name: "Sam Smith", image: "sam-smith", tracks: []))
    }
}
