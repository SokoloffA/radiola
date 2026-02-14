//
//  Types.swift
//  Radiola
//
//  Created by Alex Sokolov on 11.05.2023.
//

import Cocoa
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
    case markAsFavorite

    init(fromString: String, defaultVal: MouseButtonAction) {
        switch fromString {
            case "showMenu": self = .showMenu
            case "playPause": self = .playPause
            case "showMainWindow": self = .showMainWindow
            case "showHistory": self = .showHistory
            case "mute": self = .mute
            case "markAsFavorite": self = .markAsFavorite
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
            case .markAsFavorite: return "markAsFavorite"
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

// MARK: - Errors

struct Alarm: Error, Identifiable {
    var id: String { title + (message ?? "") }

    let title: String
    let message: String?
    let parentError: Error?

    static let notificationName = Notification.Name("AlarmOccurred")

    /* ****************************************
     *
     * ****************************************/
    init(title: String, message: String? = nil, parentError: Error? = nil) {
        self.title = title
        self.message = message
        self.parentError = parentError
    }

    /* ****************************************
     *
     * ****************************************/
    static func show(title: String, message: String? = nil) {
        NotificationCenter.default.post(name: notificationName, object: Alarm(title: title, message: message))
    }

    /* ****************************************
     *
     * ****************************************/
    static func show(loadListErrot: Error) {
        warning("Sorry, we couldn't load stations.", loadListErrot)
        show(title: "Sorry, we couldn't load stations.", message: loadListErrot.localizedDescription)
    }
}

extension Error {
    /* ****************************************
     *
     * ****************************************/
    func show() {
        if let alarm = self as? Alarm {
            if let parentError = alarm.parentError {
                warning("Error: \(alarm.title), \(alarm.message ?? ""). Parent error: \(parentError)")
            } else {
                warning("Error: \(alarm.title), \(alarm.message ?? "")")
            }
            NotificationCenter.default.post(name: Alarm.notificationName, object: alarm)
        } else {
            NotificationCenter.default.post(name: Alarm.notificationName, object: Alarm(title: "Error", message: "\(self)"))
        }
    }
}

/* ****************************************
 *
 * ****************************************/
fileprivate var logsData: [String] = []

/* ****************************************
 *
 * ****************************************/
func allLogs() -> [String] {
    return logsData
}

/* ****************************************
 *
 * ****************************************/
fileprivate func logMsg(prefix: String, _ items: Any..., separator: String = " ", terminator: String = "\n") {
    let s = prefix + ": \(Date()) [\(pthread_mach_thread_np(pthread_self()))] " + items.map { "\($0)" }.joined(separator: separator)
    logsData.append(s)
    print(s)
}

/* ****************************************
 *
 * ****************************************/
func debug(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    logMsg(prefix: "Debug", items, separator: separator, terminator: terminator)
}

/* ****************************************
 *
 * ****************************************/
func warning(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    logMsg(prefix: "Warning", items, separator: separator, terminator: terminator)
}

// MARK: - NSMenuItem

extension NSMenuItem {
    convenience init(title: String, keyEquivalent: String = "", action: @escaping () -> Void) {
        self.init(title: title, action: nil, keyEquivalent: keyEquivalent)
        let actionHandler = Handler(action: action)
        target = actionHandler
        self.action = #selector(Handler.executeAction)
        objc_setAssociatedObject(self, "[\(title)-actionHandler]", actionHandler, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private class Handler {
        private let action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func executeAction() {
            action()
        }
    }
}

// MARK: - NSMenu

extension NSMenu {
    func addItem(withTitle: String, keyEquivalent: String = "", action: @escaping () -> Void) {
        addItem(NSMenuItem(title: withTitle, keyEquivalent: keyEquivalent, action: action))
    }
}
