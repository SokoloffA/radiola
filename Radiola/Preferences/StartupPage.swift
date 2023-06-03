//
//  StartupPage.swift
//  Radiola
//
//  Created by Paulchen Panther on 06.05.2023.
//

import Cocoa

class StartupPage: NSViewController {
    @IBOutlet var playLastStationCheckbox: NSButton!
    @IBOutlet var playLastStation: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        playLastStation.state = settings.playLastStation ? .on : .off
    }

    @IBAction func showPlayLastStationChanged(_ sender: NSButton) {
        settings.playLastStation = playLastStation.state == .on
        NotificationCenter.default.post(name: Notification.Name.SettingsChanged, object: nil)
    }
}
