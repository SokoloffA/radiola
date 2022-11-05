//
//  AddStationDialog.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 06.07.2022.
//

import Cocoa

class AddGroupDialog: NSWindowController, NSTextFieldDelegate {

    @IBOutlet weak var titleEdit: NSTextField!
    @IBOutlet weak var okButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    
    var title: String { return titleEdit?.stringValue ?? "" }

    /* ****************************************
     *
     * ****************************************/
    override var windowNibName: String! {
        return "AddGroupDialog"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

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
