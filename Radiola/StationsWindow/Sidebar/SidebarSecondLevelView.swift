//
//  SidebarSecondLevelView.swift
//  Radiola
//
//  Created by Alex Sokolov on 24.08.2023.
//

import Cocoa

class SidebarSecondLevelView: NSView {
    @IBOutlet var iconView: NSImageView!
    @IBOutlet var titleLabel: NSTextField!

    /* ****************************************
     *
     * ****************************************/
    init(title: String, icon: String) {
        super.init(frame: NSRect.zero)
        _ = load(fromNIBNamed: "SidebarSecondLevelView")
        titleLabel.stringValue = title

        if !icon.isEmpty {
            iconView.image = NSImage(systemSymbolName: NSImage.Name(icon), accessibilityDescription: "")
        }
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
