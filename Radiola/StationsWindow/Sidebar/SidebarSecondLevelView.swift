//
//  SidebarSecondLevelView.swift
//  Radiola
//
//  Created by Alex Sokolov on 24.08.2023.
//

import Cocoa

class SidebarSecondLevelView: NSView {
    @IBOutlet var iconLabel: NSTextField!
    @IBOutlet var titleLabel: NSTextField!

    /* ****************************************
     *
     * ****************************************/
    init(item: SideBar.Item) {
        super.init(frame: NSRect.zero)
        _ = load(fromNIBNamed: "SidebarSecondLevelView")
        // titleLabel.stringValue = item.title
        wantsLayer = true
        layer?.backgroundColor = NSColor.red.cgColor
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
