//
//  LogsWindow.swift
//  Radiola
//
//  Created by Alex Sokolov on 16.11.2024.
//

import Cocoa

// MARK: - LogsWindow

class LogsWindow: NSWindowController, NSWindowDelegate {
    private static var instance: LogsWindow?
    private let logsView = NSTextView()
    private let copyButton = NSButton()

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(window: nil)
        let window = NSWindow(contentRect: NSMakeRect(0, 0, 800, 600),
                              styleMask: [.titled, .closable, .resizable],
                              backing: .buffered, defer: false)

        window.delegate = self
        self.window = window
        window.title = NSLocalizedString("Radiola logs", comment: "Window title")

        guard let windowContentView = window.contentView else { return }
        windowContentView.autoresizingMask = [.maxXMargin, .minYMargin]

        windowContentView.addSubview(logsView)
        windowContentView.addSubview(copyButton)

        logsView.isEditable = false
        logsView.isSelectable = true
        logsView.string = allLogs().joined()

        copyButton.title = NSLocalizedString("Copy to clipboard", comment: "Button label")
        copyButton.target = self
        copyButton.action = #selector(copyToClipboard)

        logsView.translatesAutoresizingMaskIntoConstraints = false
        logsView.topAnchor.constraint(equalTo: windowContentView.topAnchor, constant: 8).isActive = true
        logsView.leadingAnchor.constraint(equalTo: windowContentView.leadingAnchor, constant: 8).isActive = true
        logsView.trailingAnchor.constraint(equalTo: windowContentView.trailingAnchor, constant: 8).isActive = true

        copyButton.translatesAutoresizingMaskIntoConstraints = false
        copyButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        copyButton.topAnchor.constraint(equalToSystemSpacingBelow: logsView.bottomAnchor, multiplier: 3).isActive = true
        windowContentView.bottomAnchor.constraint(equalToSystemSpacingBelow: copyButton.bottomAnchor, multiplier: 1).isActive = true
        windowContentView.trailingAnchor.constraint(equalToSystemSpacingAfter: copyButton.trailingAnchor, multiplier: 1).isActive = true

        window.center()
    }

    /* ****************************************
     *
     * ****************************************/
    func windowWillClose(_ notification: Notification) {
        LogsWindow.instance = nil
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        fatalError()
    }

    /* ****************************************
     *
     * ****************************************/
    class func show() {
        if instance == nil {
            instance = LogsWindow()
        }

        instance?.window?.show()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(logsView.string, forType: .string)
    }
}
