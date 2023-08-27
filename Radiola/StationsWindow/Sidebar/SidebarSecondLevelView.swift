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
    init(item: SideBar.Item) {
        super.init(frame: NSRect.zero)
        _ = load(fromNIBNamed: "SidebarSecondLevelView")
        titleLabel.stringValue = item.title
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
