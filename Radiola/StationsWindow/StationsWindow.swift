//
//  StationsWindow.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 05.07.2022.
//

import Cocoa

class StationsWindow: NSWindowController, NSWindowDelegate {
    private static var instance: StationsWindow?

    let stationsView = StationView()
    @IBOutlet var splitView: NSSplitView!

    /* ****************************************
     *
     * ****************************************/
    override var windowNibName: String! {
        return "StationsWindow"
    }

    /* ****************************************
     *
     * ****************************************/
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.delegate = self

        // splitView.addArrangedSubview(NSView())
        splitView.addArrangedSubview(stationsView)

        stationsView.stations = stationsStore.root
    }

    /* ****************************************
     *
     * ****************************************/
    class func isActie() -> Bool {
        return instance != nil
    }

    /* ****************************************
     *
     * ****************************************/
    class func show() -> StationsWindow {
        if instance == nil {
            instance = StationsWindow()
        }

        NSApp.setActivationPolicy(.regular)
        instance?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        return instance!
    }

    func windowWillClose(_ notification: Notification) {
        StationsWindow.instance = nil
    }
}

//
//    /* ****************************************
//     *
//     * ****************************************/
//    override public func mouseDown(with event: NSEvent) {
//        if NSPointInRect(event.locationInWindow, titleBar.frame) {
//            window?.performDrag(with: event)
//        }
//    }
//
