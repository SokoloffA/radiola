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
    init(group: SideBar.Group) {
        super.init(frame: NSRect.zero)
        _ = load(fromNIBNamed: "SidebarTopLevelView")
        titleLabel.stringValue = group.title
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
