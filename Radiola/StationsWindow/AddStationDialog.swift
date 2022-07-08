//
//  AddStationDialog.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 06.07.2022.
//

import Cocoa

class AddStationDialog: NSWindowController, NSTextFieldDelegate {

    
    @IBOutlet weak var titleEdit: NSTextField!
    @IBOutlet weak var urlEdit: NSTextField!
    @IBOutlet weak var okButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    
    var title: String { get { return titleEdit?.stringValue ?? "" } }
    var url:   String { get { return urlEdit?.stringValue ?? "" } }

    
    /* ****************************************
     *
     * ****************************************/
    override var windowNibName: String! {
        return "AddStationDialog"
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
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
