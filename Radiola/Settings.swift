//
//  Settings.swift
//  Radiola
//
//  Created by Alex Sokolov on 27.11.2022.
//

import Foundation

class Settings {
    private let lastStationKey = "Url"
    // private let recentStationsKey = "RecentStations"
    private let volumeLevelKey = "Volume"
    private let showVolumeInMenuKey = "ShowVolumeInMenu"

    private let recentStationsLengt = 5

    private let data = UserDefaults.standard

    init() {
        let defaults: [String: Any] = [
            volumeLevelKey: 0.5,
            showVolumeInMenuKey: false,
        ]
        data.register(defaults: defaults)
    }

    var lastStationUrl: String? {
        get { data.string(forKey: lastStationKey) }
        set { data.set(newValue, forKey: lastStationKey) }
    }

    var volumeLevel: Float {
        get { data.float(forKey: volumeLevelKey) }
        set { data.set(newValue, forKey: volumeLevelKey) }
    }

    var showVolumeInMenu: Bool {
        get { data.bool(forKey: showVolumeInMenuKey) }
        set { data.set(newValue, forKey: showVolumeInMenuKey) }
    }
}

let settings = Settings()
