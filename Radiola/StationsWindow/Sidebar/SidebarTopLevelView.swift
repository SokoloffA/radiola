//
//  SidebarTopLevelView.swift
//  Radiola
//
//  Created by Alex Sokolov on 24.08.2023.
//

import Cocoa

class SidebarTopLevelView: NSView {
    @IBOutlet var titleLabel: NSTextField!

    /* ****************************************
     *
     * ****************************************/
    init(item: SideBar.Item) {
        super.init(frame: NSRect.zero)
        _ = load(fromNIBNamed: "SidebarTopLevelView")
        titleLabel.stringValue = item.title
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
