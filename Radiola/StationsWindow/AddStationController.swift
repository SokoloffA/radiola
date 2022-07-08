//
//  AddStationController.swift
//  Radiola
//
//  Created by Alex Sokolov on 11.11.2020.
//  Copyright © 2020 Alex Sokolov. All rights reserved.
//

import Cocoa

class AddStationController: NSViewController, NSTextFieldDelegate {


    @IBOutlet weak var urlEdit: NSTextField!
    @IBOutlet weak var titleEdit: NSTextField!
    @IBOutlet weak var okButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        urlEdit.delegate = self
        titleEdit.delegate = self
        okButton.isEnabled = false
    }
    
    public var url = ""
    public var name = ""
    
    func controlTextDidChange(_ obj: Notification) {
        okButton.isEnabled =
            !urlEdit.stringValue.isEmpty &&
            !titleEdit.stringValue.isEmpty
    }
    
    @IBAction func cancel(_ sender: Any) {
        guard let window = self.view.window, let parent = window.sheetParent else { return }
        parent.endSheet(window, returnCode: .cancel)
    }
    
    @IBAction func addStation(_ sender: Any) {
        guard let window = self.view.window, let parent = window.sheetParent else { return }

        url  = urlEdit?.stringValue ?? ""
        name = titleEdit?.stringValue ?? ""
        
        parent.endSheet(window, returnCode: .OK)
    }
}
