//
//  AddStationDialog.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 06.07.2022.
//

import Cocoa

class AddStationDialog: NSWindowController, NSTextFieldDelegate {
    @IBOutlet var messageLabel: NSTextField!
    @IBOutlet var titleEditLabel: NSTextField!
    @IBOutlet var urlEditLabel: NSTextField!
    @IBOutlet var titleEdit: NSTextField!
    @IBOutlet var urlEdit: NSTextField!
    @IBOutlet var okButton: NSButton!
    @IBOutlet var cancelButton: NSButton!

    var title: String { return titleEdit?.stringValue ?? "" }
    var url: String { return urlEdit?.stringValue ?? "" }

    /* ****************************************
     *
     * ****************************************/
    override var windowNibName: String! {
        return "AddStationDialog"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        messageLabel.stringValue = NSLocalizedString("To add a station, fill out the following information:", comment: "Add station dialog message")
        titleEditLabel.stringValue = NSLocalizedString("Title:", comment: "Add station dialog label for Tile edit")
        urlEditLabel.stringValue = NSLocalizedString("URL:", comment: "Add station dialog label for URL edit")

        cancelButton.title = NSLocalizedString("Cancel", comment: "Cancel button")
        okButton.title = NSLocalizedString("Add station", comment: "Add station dialog button")

        urlEdit.delegate = self
        titleEdit.delegate = self
        okButton.isEnabled = false
    }

    func controlTextDidChange(_ obj: Notification) {
        okButton.isEnabled =
            !urlEdit.stringValue.isEmpty &&
            !titleEdit.stringValue.isEmpty
    }

    @IBAction func cancelClicked(_ sender: Any) {
        window?.sheetParent?.endSheet(window!, returnCode: .cancel)
    }

    @IBAction func okClick(_ sender: Any) {
        window?.sheetParent?.endSheet(window!, returnCode: .OK)
    }
}
