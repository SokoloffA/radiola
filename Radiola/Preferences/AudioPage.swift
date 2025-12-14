//
//  AudioPage.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 10.12.2022.
//

import Cocoa

class AudioPage: NSViewController {
    @IBOutlet var deviceCombobox: NSPopUpButton!
    @IBOutlet var deviceLabel: NSTextField!

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(nibName: nil, bundle: nil)
        title = NSLocalizedString("Audio", tableName: "Settings", comment: "Settings tab title")
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /* ****************************************
     *
     * ****************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        deviceLabel.stringValue = NSLocalizedString("Device:", tableName: "Settings", comment: "Settings label")

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshDeviceCombo),
            name: Notification.Name.AudioDeviceChanged,
            object: nil)

        refreshDeviceCombo()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func refreshDeviceCombo() {
        debug("[Settings] The list of audio devices has changed")
        AudioSytstem.debugAudioDevices(prefix: "[Settings]")

        let sel = settings.audioDevice

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
        let deviceUID = (deviceCombobox.selectedItem?.representedObject as? AudioDevice)?.UID
        if settings.audioDevice != deviceUID {
            debug("[Settings] Select audio device \(deviceUID ?? "nil")")
            settings.audioDevice = deviceUID
            NotificationCenter.default.post(name: Notification.Name.SettingsChanged, object: nil)
        }
    }
}
