//
//  PlaylistCellView.swift
//  Music Player X
//
//  Created by Richard Pacheco on 7/4/23.
//

import SwiftUI

struct PlaylistCellView: View {
    var playlist: Playlist
    
    var body: some View {
        VStack(alignment: .leading) {
            Image(playlist.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(playlist.title)
                .lineLimit(2)
                .font(.subheadline)
                .frame(height: 40)
        }
        .frame(width: 150)
    }
}

struct PlaylistCellView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistCellView(playlist: Playlist(title: "Richard work's station", image: "cover1", tracks: [""]))
    }
}
