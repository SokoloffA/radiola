//
//  RadiolaApp.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 30.11.2023.
//

import SwiftUI

@main
struct RadiolaApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject var appState = AppState()

    /* ****************************************
     *
     * ****************************************/
    var body: some Scene {
        WindowGroup {
            MainWindow()
                .environmentObject(appState)
        }

        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
    }
}
