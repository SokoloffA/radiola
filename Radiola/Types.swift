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

    /* ****************************************
     *
     * ****************************************/
    func show(window: NSWindow) {
        guard let alarm = self as? Alarm else { return }

        let alert = NSAlert()
        alert.messageText = alarm.title
        alert.alertStyle = .critical

        if let informativeText = alarm.message {
            alert.informativeText = informativeText
        }

        alert.beginSheetModal(for: window)
    }
}

// MARK: - RadiolaError

struct RadiolaError: LocalizedError {
    let message: String
    var errorDescription: String? { return message }

    init(_ message: String) {
        self.message = message
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

// MARK: -  AtomicBool

class AtomicBool: @unchecked Sendable {
    private var val: Bool = false
    private var mutex = pthread_mutex_t()

    init(val: Bool = false) {
        pthread_mutex_init(&mutex, nil)
        value = val
    }

    deinit {
        pthread_mutex_destroy(&mutex)
    }

    var value: Bool {
        get {
            pthread_mutex_lock(&mutex)
            let res = val
            pthread_mutex_unlock(&mutex)
            return res
        }
        set {
            pthread_mutex_lock(&mutex)
            val = newValue
            pthread_mutex_unlock(&mutex)
        }
    }
}

// MARK: - String

extension String {
    /* ****************************************
     *
     * ****************************************/
    func truncateMiddle(maxLength: Int, separator: String = "…") -> String {
        guard count > maxLength else { return self }

        let separatorLength = separator.count
        let available = maxLength - separatorLength
        let leftTarget = available / 2
        let rightTarget = available - leftTarget

        // Left side: take no more than leftTarget characters, but do not split the word
        var leftPart = ""
        if leftTarget > 0 {
            let prefix = String(prefix(leftTarget + 1)) // +1 для проверки пробела
            if let lastSpaceIndex = prefix.lastIndex(where: { $0.isWhitespace }) {
                // Trim to the last space (excluding the space in the result)
                leftPart = String(self[startIndex ..< lastSpaceIndex])
            } else {
                leftPart = String(self.prefix(leftTarget))
            }
        }

        // Right side: take no more than rightTarget characters, starting from the end
        var rightPart = ""
        if rightTarget > 0 {
            let suffix = String(suffix(rightTarget + 1)) // +1 для проверки пробела
            if let firstSpaceIndex = suffix.firstIndex(where: { $0.isWhitespace }) {
                // Start after the first space (or move forward)
                let start = suffix.index(after: firstSpaceIndex)
                rightPart = String(suffix[start...])
            } else {
                rightPart = String(self.suffix(rightTarget))
            }
        }

        // If some of the sections are left blank after the adjustment, revert to the standard truncation (without words)
        if leftPart.isEmpty && rightPart.isEmpty {
            let simple = String(prefix(leftTarget)) + separator + String(suffix(rightTarget))
            return simple
        }

        return leftPart + separator + rightPart
    }
}
