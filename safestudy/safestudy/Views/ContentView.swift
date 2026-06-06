//
//  ContentView.swift
//  safestudy
//
//  Created by Katha on 3/22/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Discover", systemImage: "map")
            }

            NavigationStack {
                SavedFavoritesView()
            }
            .tabItem {
                Label("Favorites", systemImage: "heart.fill")
            }
        }
        .background(AppTheme.background)
    }
}
