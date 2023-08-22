//
//  Track.swift
//  Music Player X
//
//  Created by Richard Pacheco on 7/4/23.
//

import Foundation

struct Track {
    let id = UUID()
    var name: String
    var album: String
    var cover: String
    var artist: Artist
    var url : URL?
    var durationString: String?
}
