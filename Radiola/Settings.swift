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
    private let mediaKeysKey = "MediaKeys"
    private let mediaPrevNextKeyActionKey = "MediaPrevNextAction"
    private let mouseWheelActionKey = "MouseWheelAction"
    private let showMuteInMenuKey = "ShowMuteInMenu"
    private let showTooltipKey = "ShowTooltip"
    private let showCopyToClipboardInMenuKey = "ShowCopyToClipboardInMenu"

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

    enum StationsListMode: Int {
        case opml
        case cloud
        case both
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
            showMuteInMenuKey: false,
            showTooltipKey: true,
            showCopyToClipboardInMenuKey: false,
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

    /* ****************************************
     *
     * ****************************************/
    var mediaPrevNextKeyAction: MediaPrevNextKeyAction {
        get {
            let s = data.string(forKey: mediaPrevNextKeyActionKey) ?? ""
            if s == "disable" { return .disable }
            if s == "switchStation" { return .switchStation }
            return .disable
        }

        set {
            switch newValue {
                case .disable: data.set("disable", forKey: mediaPrevNextKeyActionKey)
                case .switchStation: data.set("switchStation", forKey: mediaPrevNextKeyActionKey)
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    var mouseWheelAction: MouseWheelAction {
        get {
            let s = data.string(forKey: mouseWheelActionKey) ?? ""
            if s == "nothing" { return .nothing }
            if s == "volume" { return .volume }
            return .nothing
        }

        set {
            switch newValue {
                case .nothing: data.set("nothing", forKey: mouseWheelActionKey)
                case .volume: data.set("volume", forKey: mouseWheelActionKey)
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    var showMuteInMenu: Bool {
        get { data.bool(forKey: showMuteInMenuKey) }
        set { data.set(newValue, forKey: showMuteInMenuKey) }
    }

    /* ****************************************
     *
     * ****************************************/
    var showTooltip: Bool {
        get { data.bool(forKey: showTooltipKey) }
        set { data.set(newValue, forKey: showTooltipKey) }
    }

    /* ****************************************
     *
     * ****************************************/
    var showCopyToClipboardInMenu: Bool {
        get { data.bool(forKey: showCopyToClipboardInMenuKey) }
        set { data.set(newValue, forKey: showCopyToClipboardInMenuKey) }
    }

    /* ****************************************
     *
     * ****************************************/
    @Setting("ShowNotificationWhenPlaybackStarts", default: false)
    var showNotificationWhenPlaybackStarts: Bool
}

let settings = Settings()

@propertyWrapper
struct Setting<Value> {
    private let key: String
    private let defaultValue: Value
    private let data: UserDefaults

    /* ****************************************
     *
     * ****************************************/
    init(_ key: String, default defaultValue: Value, data: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.data = data
    }

    /* ****************************************
     *
     * ****************************************/
    var wrappedValue: Value {
        get { data.object(forKey: key) as? Value ?? defaultValue }
        set { data.set(newValue, forKey: key) }
    }
}
