//
//  SafeStudyApp.swift
//  safestudy
//
//  Created by Katha on 3/22/26.
//

import SwiftUI

@main
struct SafeStudyApp: App {
    @StateObject private var viewModel = SafeStudyViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .tint(AppTheme.primary)
        }
    }
}
