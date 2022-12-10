//
//  AudioPage.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 10.12.2022.
//

import Cocoa

class AudioPage: NSViewController {
    private var deviceUIDs: [String?] = []
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
    private func selectedDeviceUID() -> String? {
        let n = deviceCombobox.indexOfSelectedItem
        if n > -1 && n < deviceUIDs.count {
            return deviceUIDs[n]
        }

        return nil
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func refreshDeviceCombo() {
        let sel = player.audioDeviceUID // selectedDeviceUID()

        deviceCombobox.removeAllItems()
        deviceUIDs.removeAll()

        deviceUIDs.append(nil)
        deviceCombobox.addItem(withTitle: "System Default Device")

        let devices = AudioSytstem.devices()
        for d in devices {
            deviceUIDs.append(d.UID)
            deviceCombobox.addItem(withTitle: d.name)

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
        player.audioDeviceUID = selectedDeviceUID()
    }
}
