//
//  AudioPage.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 10.12.2022.
//

import Cocoa

class AudioPage: PreferencesPage {
    private let deviceCombobox = NSPopUpButton()
    private let deviceLabel = NSLocalizedString("Device:", tableName: "Settings", comment: "Settings label")
    /* ****************************************
     *
     * ****************************************/
    override init() {
        super.init()
        title = NSLocalizedString("Audio", tableName: "Settings", comment: "Settings tab title")

        addRow(title: deviceLabel, rightView: deviceCombobox)

        deviceCombobox.target = self
        deviceCombobox.action = #selector(deviceChanged)

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
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    @objc private func deviceChanged(_ sender: Any) {
        let deviceUID = (deviceCombobox.selectedItem?.representedObject as? AudioDevice)?.UID
        if settings.audioDevice != deviceUID {
            debug("[Settings] Select audio device \(deviceUID ?? "nil")")
            settings.audioDevice = deviceUID
            NotificationCenter.default.post(name: Notification.Name.SettingsChanged, object: nil)
        }
    }
}
