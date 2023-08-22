//
//  Draggable.swift
//  Music Player X
//
//  Created by Richard Pacheco on 7/9/23.
//

import SwiftUI

struct DraggableModifier : ViewModifier {

    enum Direction {
        case vertical
        case horizontal
    }

    let direction: Direction
    var onEnded: (DragGesture.Value) -> Void
    var onChange: (DragGesture.Value) -> Void

    @State private var draggedOffset: CGSize = .zero

    func body(content: Content) -> some View {
        content
        .offset(
            CGSize(width: direction == .vertical ? 0 : draggedOffset.width,
                   height: direction == .horizontal ? 0 : draggedOffset.height)
        )
        .gesture(
            DragGesture()
            .onChanged(onChange)
            .onEnded(onEnded)
        )
    }

}
