//
//  RadiolaApp.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 30.11.2023.
//

import SwiftUI

@main
struct RadiolaApp: App {
    @StateObject var appState = AppState()

    /* ****************************************
     *
     * ****************************************/
    var body: some Scene {
        WindowGroup {
            MainWindow()
                .environmentObject(appState)
        }
    }
}
