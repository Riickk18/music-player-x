//
//  Playlist.swift
//  Music Player X
//
//  Created by Richard Pacheco on 7/4/23.
//

import Foundation

struct Playlist {
    let id = UUID()
    var title: String
    var image: String
    var tracks: [String]//[Track]
}
