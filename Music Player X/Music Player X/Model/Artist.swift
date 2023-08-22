//
//  Artist.swift
//  Music Player X
//
//  Created by Richard Pacheco on 7/4/23.
//

import Foundation

struct Artist {
    let id = UUID()
    var name: String
    var image: String
    var tracks: [String]//[Tracks]
}
