//
//  UpdatePanel.swift
//  Radiola
//
//  Created by Alex Sokolov on 23.07.2022.
//

import Cocoa

class UpdatePanel: NSViewController {

    @IBOutlet weak var checkNowButton: NSButton!
    @IBOutlet weak var automaticallyChecksForUpdates: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        checkNowButton.target = updater
        checkNowButton.action = #selector(Updater.checkForUpdates)

        automaticallyChecksForUpdates.state  = updater.automaticallyChecksForUpdates ? .on : .off
    }
    
    @IBAction func autoUpdateClicked(_ sender: NSButton) {
        updater.automaticallyChecksForUpdates = sender.state == .on
    }
}
