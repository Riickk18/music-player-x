//
//  Int+Extensions.swift
//  Music Player X
//
//  Created by Richard Pacheco on 7/5/23.
//

import CoreGraphics

public protocol RepresentableAsInt {
    var asInt: Int {get}
}

extension Int: RepresentableAsInt {
    public var asInt: Int {
        self
    }
}
