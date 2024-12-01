//
//  LogsWindow.swift
//  Radiola
//
//  Created by Alex Sokolov on 01.12.2024.
//

import Cocoa

class LogsWindow: NSWindowController, NSWindowDelegate {
    private static var instance: LogsWindow?
    @IBOutlet var logsView: NSTextView!
    @IBOutlet var copyButton: NSButton!

    /* ****************************************
     *
     * ****************************************/
    override var windowNibName: String! {
        return "LogsWindow"
    }

    /* ****************************************
     *
     * ****************************************/
    override func windowDidLoad() {
        super.windowDidLoad()

        window?.delegate = self
        window?.title = NSLocalizedString("Radiola logs", comment: "Window title")

        logsView.isEditable = false
        logsView.isSelectable = true
        logsView.textContainerInset = NSSize(width: 8, height: 8)
        logsView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        logsView.string = allLogs().joined(separator: "\n") + "\n"

        copyButton.title = NSLocalizedString("Copy to clipboard", comment: "Button label")
        copyButton.target = self
        copyButton.action = #selector(copyToClipboard)

        window?.center()
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
    func windowWillClose(_ notification: Notification) {
        LogsWindow.instance = nil
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
