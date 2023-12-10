//
//  AppState.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 01.12.2023.
//

import Foundation

// MARK: - AppState

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var localStations: [LocalStationProvider] = [
        LocalStationProvider(title: "My stations", icon: "music.house", help: nil),
    ]

    @Published var internetStations: [InternetStationProvider] = [
        RadioBrowserProvider(type: .byTag, title: "By tag", icon: "globe", help: nil),
        RadioBrowserProvider(type: .byName, title: "By name", icon: "globe", help: nil),
        RadioBrowserProvider(type: .byCountry, title: "By country", icon: "globe", help: nil),
    ]

    /* ****************************************
     *
     * ****************************************/
    func favoritesStations() -> [Station] {
        return []
        // return filterStations { $0.isFavorite }
    }
}
