//
//  Settings.swift
//  Radiola
//
//  Created by Alex Sokolov on 27.11.2022.
//

import Foundation

class Settings {
    private let data = UserDefaults.standard

    private let lastStationKey = "Url"
    private let volumeLevelKey = "Volume"
    private let volumeIsMutedKey = "Muted"
    private let showVolumeInMenuKey = "ShowVolumeInMenu"
    private let favoritesMenuTypeKey = "FavoritesMenuType"
    private let audioDeviceKey = "AudioDevice"
    private let playLastStationKey = "playLastStation"
    private let mediaKeysKey = "MmediaKeys"

    private var mouseActs: [MouseButton: MouseButtonAction] = [:]

    enum FavoritesMenuType: Int {
        case flat
        case margin
        case submenu
    }

    enum MediaKeysHandleType: Int {
        case enable
        case disable
        case mainWindowActive
    }

    /* ****************************************
     *
     * ****************************************/
    init() {
        let defaults: [String: Any] = [
            volumeLevelKey: 0.5,
            volumeIsMutedKey: false,
            showVolumeInMenuKey: false,
            playLastStationKey: false,
            mediaKeysKey: true,
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

    /* ****************************************
     *
     * ****************************************/
    var playLastStation: Bool {
        get { data.bool(forKey: playLastStationKey) }
        set { data.set(newValue, forKey: playLastStationKey) }
    }

    /* ****************************************
     *
     * ****************************************/
    private func mouseActionKey(forButton: MouseButton) -> String {
        switch forButton {
            case .left: return "LeftButtonAction"
            case .right: return "RightButtonAction"
            case .middle: return "MiddleButtonAction"
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func mouseAction(forButton: MouseButton) -> MouseButtonAction {
        let res = mouseActs[forButton]
        if res != nil {
            return res!
        }

        let s = data.string(forKey: mouseActionKey(forButton: forButton)) ?? ""
        let v = MouseButtonAction(fromString: s, defaultVal: .showMenu)
        mouseActs[forButton] = v
        return v
    }

    /* ****************************************
     *
     * ****************************************/
    func setMouseAction(forButton: MouseButton, action: MouseButtonAction) {
        mouseActs[forButton] = action
        data.set(action.toString(), forKey: mouseActionKey(forButton: forButton))
        NotificationCenter.default.post(name: Notification.Name.SettingsChanged, object: nil)
    }

    /* ****************************************
     *
     * ****************************************/
    var mediaKeysHandle: MediaKeysHandleType {
        get {
            let s = data.string(forKey: mediaKeysKey) ?? ""
            if s == "enable" { return .enable }
            if s == "disable" { return .disable }
            if s == "mainWindowActive" { return .mainWindowActive }
            return .enable
        }

        set {
            switch newValue {
                case .enable: data.set("enable", forKey: mediaKeysKey)
                case .disable: data.set("disable", forKey: mediaKeysKey)
                case .mainWindowActive: data.set("mainWindowActive", forKey: mediaKeysKey)
            }
        }
    }
}

let settings = Settings()
