//
//  TabBarView.swift
//  Music Player X
//
//  Created by Richard Pacheco on 7/4/23.
//

import SwiftUI

struct TabBarView: View {
    @StateObject var viewModel = PlayerViewModel.shared
    @Namespace var namespace

    var body: some View {
        ZStack {
            TabView {
                Text("Main")
                    .tabItem {
                        Image(systemName: "menubar.dock.rectangle")
                            .renderingMode(.template)
                        Text("Today")
                    }
                Text("Games")
                    .tabItem {
                        Image(systemName: "gamecontroller")
                            .renderingMode(.template)
                        Text("Games")
                    }
                Text("Apps")
                    .tabItem {
                        Image(systemName: "apps.iphone")
                            .renderingMode(.template)
                        Text("Apps")
                    }
                Text("Search")
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                            .renderingMode(.template)
                        Text("Search")
                    }
            }

            if viewModel.showPlayerFullScreen {
                FullScreenPlayerView(namespace: namespace)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !viewModel.showPlayerFullScreen {
                CompactPlayerView(namespace: namespace)
                    .padding(.bottom, 60)
            }
        }
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}
