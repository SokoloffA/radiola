//
//  AddStationDialog.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 06.07.2022.
//

import Cocoa

class AddGroupDialog: OkCancelDialog, NSTextFieldDelegate {
    private let titleLabel = NSLocalizedString("Title:", comment: "Add group dialog label for TileEdit")
    private let titleEdit = NSTextField()

    var title: String { return titleEdit.stringValue }

    /* ****************************************
     *
     * ****************************************/
    override init(size: NSSize? = nil) {
        super.init(size: size)
        messageLabel.stringValue = NSLocalizedString("To add a group, fill out the following information:", comment: "Add group dialog message")
        okButton.title = NSLocalizedString("Add group", comment: "Add group dialog button")

        gridView.addRow(title: titleLabel, rightView: titleEdit)

        titleEdit.delegate = self

        updateButtons()
    }

    /* ****************************************
     *
     * ****************************************/
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /* ****************************************
     *
     * ****************************************/
    func controlTextDidChange(_ obj: Notification) {
        updateButtons()
    }

    /* ****************************************
     *
     * ****************************************/
    private func updateButtons() {
        okButton.isEnabled = !titleEdit.stringValue.isEmpty
    }
}
