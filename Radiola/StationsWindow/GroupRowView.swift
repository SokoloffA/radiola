//
//  RowView.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 22.06.2022.
//  Copyright © 2022 Alex Sokolov. All rights reserved.
//

import Cocoa

class GroupRowView: NSView {
    @IBOutlet var nameEdit: NSTextField!

    private weak var stationView: StationView!
    private let group: StationGroup

    /* ****************************************
     *
     * ****************************************/
    init(group: StationGroup, stationView: StationView) {
        self.group = group
        self.stationView = stationView
        super.init(frame: NSRect.zero)
        _ = load(fromNIBNamed: "GroupRowView")

        nameEdit.stringValue = group.title
        nameEdit.tag = group.id
        if stationView.isEditable {
            nameEdit.target = self
            nameEdit.action = #selector(nameEdited(sender:))
        }
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        group = StationGroup(title: "")
        super.init(coder: coder)
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction private func nameEdited(sender: NSTextField) {
        group.title = sender.stringValue
        stationView.nodeDidChanged(node: group)
    }
}
