//
//  PreferencesWindow.swift
//  Radiola
//
//  Created by Alex Sokolov on 23.07.2022.
//

import Cocoa

class PreferencesWindow: NSWindowController, NSTabViewDelegate, NSWindowDelegate {
    private let viewController: NSTabViewController!

    /* ****************************************
     *
     * ****************************************/
    init() {
        viewController = NSTabViewController()
        super.init(window: NSWindow(contentViewController: viewController))
        windowFrameAutosaveName = "PreferencesWindow"

        var tab = NSTabViewItem(viewController: ControlsPage())
        tab.label = tab.viewController?.title ?? ""
        tab.image = NSImage(systemSymbolName: "computermouse", accessibilityDescription: "")
        viewController.addTabViewItem(tab)
        tab.viewController?.title = tab.label

        tab = NSTabViewItem(viewController: AppearancePage())
        tab.label = tab.viewController?.title ?? ""
        tab.image = NSImage(systemSymbolName: "filemenu.and.cursorarrow", accessibilityDescription: "")
        viewController.addTabViewItem(tab)
        tab.viewController?.title = tab.label

        tab = NSTabViewItem(viewController: AudioPage())
        tab.label = tab.viewController?.title ?? ""
        tab.image = NSImage(systemSymbolName: "hifispeaker.2", accessibilityDescription: "")
        viewController.addTabViewItem(tab)
        tab.viewController?.title = tab.label

        tab = NSTabViewItem(viewController: AdvancedPage())
        tab.label = tab.viewController?.title ?? ""
        tab.image = NSImage(systemSymbolName: NSImage.Name("gearshape.2"), accessibilityDescription: "Advanced page")
        viewController.addTabViewItem(tab)
        tab.viewController?.title = tab.label

        tab = NSTabViewItem(viewController: UpdatePanel())
        tab.label = tab.viewController?.title ?? ""
        tab.image = NSImage(systemSymbolName: "icloud.and.arrow.down", accessibilityDescription: "")
        viewController.addTabViewItem(tab)
        tab.viewController?.title = tab.label

        viewController.tabStyle = .toolbar
        contentViewController = viewController

        window?.delegate = self
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

        instance?.window?.show()
        return instance!
    }
}
