//
//  ContentView.swift
//  Music Player X
//
//  Created by Richard Pacheco on 7/4/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = PlayerViewModel.shared
    @Namespace var namespace
    
    var body: some View {
        VStack {
            if viewModel.showPlayerFullScreen {
                FullScreenPlayerView(namespace: namespace)
            } else {
                Spacer()
                CompactPlayerView(namespace: namespace)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
