//
//  PreferencesWindow.swift
//  Radiola
//
//  Created by Alex Sokolov on 23.07.2022.
//

import Cocoa

class PreferencesWindow: NSWindowController, NSTabViewDelegate {
    private let viewController: NSTabViewController!

    /* ****************************************
     *
     * ****************************************/
    init() {
        viewController = NSTabViewController()
        super.init(window: NSWindow(contentViewController: viewController))
        windowFrameAutosaveName = "PreferencesWindow"

        var tab = NSTabViewItem(viewController: AppearancePage())
        tab.label = "Appearance"
        tab.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "")
        viewController.addTabViewItem(tab)

        tab = NSTabViewItem(viewController: UpdatePanel())
        tab.label = "Updates"
        tab.image = NSImage(systemSymbolName: "icloud.and.arrow.down", accessibilityDescription: "")
        viewController.addTabViewItem(tab)

        viewController.tabStyle = .toolbar
        contentViewController = viewController
        // viewController.wnd = window
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
    func windowWillClose(_ notification: Notification) {
        PreferencesWindow.instance = nil
    }

    /* ****************************************
     *
     * ****************************************/
    private static var instance: PreferencesWindow?
    class func show() -> PreferencesWindow {
        if instance == nil {
            instance = PreferencesWindow()
        }

        NSApp.setActivationPolicy(.regular)
        instance?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        return instance!
    }
}
