//
//  Types.swift
//  Radiola
//
//  Created by Alex Sokolov on 11.05.2023.
//

import Foundation

// MARK: - Simple types

enum MouseButton: Int, CaseIterable {
    case left = 0
    case right = 1
    case middle = 2
}

enum MouseButtonAction: Int {
    case showMenu
    case playPause
    case showMainWindow
    case showHistory
    case mute

    init(fromString: String, defaultVal: MouseButtonAction) {
        switch fromString {
            case "showMenu": self = .showMenu
            case "playPause": self = .playPause
            case "showMainWindow": self = .showMainWindow
            case "showHistory": self = .showHistory
            case "mute": self = .mute
            default: self = defaultVal
        }
    }

    func toString() -> String {
        switch self {
            case .showMenu: return "showMenu"
            case .playPause: return "playPause"
            case .showMainWindow: return "showMainWindow"
            case .showHistory: return "showHistory"
            case .mute: return "mute"
        }
    }
}

enum MouseWheelAction: Int {
    case nothing
    case volume
}

enum MediaPrevNextKeyAction: Int {
    case disable
    case switchStation
}

typealias Bitrate = Int

/* ****************************************
 *
 * ****************************************/
func debug(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    print("DBG: \(Date()) ", terminator: "")
    print(items, separator: separator, terminator: terminator)
}

/* ****************************************
 *
 * ****************************************/
func warning(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    print("WARN: \(Date()) ", terminator: "")
    print(items, separator: separator, terminator: terminator)
}
