//
//  AddStationDialog.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 06.07.2022.
//

import Cocoa

class AddGroupDialog: NSWindowController, NSTextFieldDelegate {
    @IBOutlet var messageLabel: NSTextField!
    @IBOutlet var titleEditLabel: NSTextField!
    @IBOutlet var titleEdit: NSTextField!
    @IBOutlet var okButton: NSButton!
    @IBOutlet var cancelButton: NSButton!

    var title: String { return titleEdit?.stringValue ?? "" }

    /* ****************************************
     *
     * ****************************************/
    override var windowNibName: String! {
        return "AddGroupDialog"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        messageLabel.stringValue = NSLocalizedString("To add a group, fill out the following information:", comment: "Add group dialog message")
        titleEditLabel.stringValue = NSLocalizedString("Title:", comment: "Add group dialog label for TileEdit")
        cancelButton.title = NSLocalizedString("Cancel", comment: "Cancel button")
        okButton.title = NSLocalizedString("Add group", comment: "Add group dialog button")

        titleEdit.delegate = self
        okButton.isEnabled = false
    }

    func controlTextDidChange(_ obj: Notification) {
        okButton.isEnabled =
            !titleEdit.stringValue.isEmpty
    }

    @IBAction func cancelClicked(_ sender: Any) {
        window?.sheetParent?.endSheet(window!, returnCode: .cancel)
    }

    @IBAction func okClicked(_ sender: Any) {
        window?.sheetParent?.endSheet(window!, returnCode: .OK)
    }
}
