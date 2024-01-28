//
//  AudioPage.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 10.12.2022.
//

import Cocoa

class AudioPage: NSViewController {
    @IBOutlet var deviceCombobox: NSPopUpButton!

    /* ****************************************
     *
     * ****************************************/
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshDeviceCombo),
                                               name: Notification.Name.AudioDeviceChanged,
                                               object: nil)

        refreshDeviceCombo()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func refreshDeviceCombo() {
        let sel = player.audioDeviceUID // selectedDeviceUID()

        deviceCombobox.removeAllItems()
        deviceCombobox.addItem(withTitle: "System Default Device")

        let devices = AudioSytstem.devices()
        for d in devices {
            deviceCombobox.addItem(withTitle: d.name)
            deviceCombobox.lastItem?.representedObject = d

            if d.UID == sel {
                deviceCombobox.select(deviceCombobox.lastItem)
            }
        }

        if deviceCombobox.selectedItem == nil {
            deviceCombobox.selectItem(at: 0)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func deviceChanged(_ sender: Any) {
        let device = deviceCombobox.selectedItem?.representedObject as? AudioDevice
        player.audioDeviceUID = device?.UID ?? nil
    }
}
