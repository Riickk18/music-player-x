//
//  Collection+Extensions.swift
//  Music Player X
//
//  Created by Richard Pacheco on 7/5/23.
//

import Foundation

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
