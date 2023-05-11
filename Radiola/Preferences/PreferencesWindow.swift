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

        var tab = NSTabViewItem(viewController: GeneralPage())
        tab.label = "General"
        tab.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "")
        viewController.addTabViewItem(tab)
        tab.viewController?.title = tab.label

        tab = NSTabViewItem(viewController: AudioPage())
        tab.label = "Audio"
        tab.image = NSImage(systemSymbolName: "hifispeaker.2", accessibilityDescription: "")
        viewController.addTabViewItem(tab)
        tab.viewController?.title = tab.label

        tab = NSTabViewItem(viewController: StartupPage())
        tab.label = "Startup"
        tab.image = NSImage(systemSymbolName: "autostartstop", accessibilityDescription: "")
        viewController.addTabViewItem(tab)
        tab.viewController?.title = tab.label

        tab = NSTabViewItem(viewController: UpdatePanel())
        tab.label = "Updates"
        tab.image = NSImage(systemSymbolName: "icloud.and.arrow.down", accessibilityDescription: "")
        viewController.addTabViewItem(tab)
        tab.viewController?.title = tab.label

        viewController.tabStyle = .toolbar
        contentViewController = viewController
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
