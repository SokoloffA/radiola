//
//  Settings.swift
//  Radiola
//
//  Created by Alex Sokolov on 27.11.2022.
//

import Foundation

class Settings {
    private let lastStationKey = "Url"
    private let volumeLevelKey = "Volume"
    private let volumeIsMutedKey = "Muted"
    private let showVolumeInMenuKey = "ShowVolumeInMenu"
    private let favoritesMenuTypeKey = "FavoritesMenuType"
    private let audioDeviceKey = "AudioDevice"

    private let data = UserDefaults.standard

    /* ****************************************
     *
     * ****************************************/
    init() {
        let defaults: [String: Any] = [
            volumeLevelKey: 0.5,
            volumeIsMutedKey: false,
            showVolumeInMenuKey: false,
        ]
        data.register(defaults: defaults)
    }

    /* ****************************************
     *
     * ****************************************/
    var lastStationUrl: String? {
        get { data.string(forKey: lastStationKey) }
        set { data.set(newValue, forKey: lastStationKey) }
    }

    /* ****************************************
     *
     * ****************************************/
    var volumeLevel: Float {
        get { data.float(forKey: volumeLevelKey) }
        set { data.set(newValue, forKey: volumeLevelKey) }
    }

    /* ****************************************
     *
     * ****************************************/
    var volumeIsMuted: Bool {
        get { data.bool(forKey: volumeIsMutedKey) }
        set { data.set(newValue, forKey: volumeIsMutedKey) }
    }

    /* ****************************************
     *
     * ****************************************/
    var showVolumeInMenu: Bool {
        get { data.bool(forKey: showVolumeInMenuKey) }
        set { data.set(newValue, forKey: showVolumeInMenuKey) }
    }

    /* ****************************************
     *
     * ****************************************/
    enum FavoritesMenuType: Int {
        case flat, margin, submenu
    }

    var favoritesMenuType: FavoritesMenuType {
        get {
            let s = data.string(forKey: favoritesMenuTypeKey) ?? ""
            if s == "submenu" { return .submenu }
            if s == "margin" { return .margin }
            return .flat
        }

        set {
            switch newValue {
            case .flat: data.set("flat", forKey: favoritesMenuTypeKey)
            case .margin: data.set("margin", forKey: favoritesMenuTypeKey)
            case .submenu: data.set("submenu", forKey: favoritesMenuTypeKey)
            }
        }
    }
    
    /* ****************************************
     *
     * ****************************************/
    var audioDevice: String? {
        get { data.string(forKey: audioDeviceKey) }
        set { data.set(newValue, forKey: audioDeviceKey) }
    }
}

let settings = Settings()