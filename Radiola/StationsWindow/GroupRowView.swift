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

    private let group: Group

    init(group: Group) {
        self.group = group
        super.init(frame: NSRect.zero)
        _ = load(fromNIBNamed: "GroupRowView")

        nameEdit.stringValue = group.name
        nameEdit.tag = group.id
        nameEdit.target = self
        nameEdit.action = #selector(nameEdited(sender:))
    }

    required init?(coder: NSCoder) {
        group = Group(name: "")
        super.init(coder: coder)
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction private func nameEdited(sender: NSTextField) {
        group.name = sender.stringValue
        stationsStore.emitChanged()
        stationsStore.write()
    }
}
