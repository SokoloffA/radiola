//
//  ToolbarVolumeItem.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 30.08.2023.
//

import Cocoa

class ToolbarVolumeView: NSViewController {
    @IBOutlet var muteButton: NSButton!
    @IBOutlet var downButton: NSButton!
    @IBOutlet var upButton: NSButton!
    @IBOutlet var slider: NSSlider!

    /* ****************************************
     *
     * ****************************************/
    override func viewDidLoad() {
        super.viewDidLoad()

        slider.minValue = 0
        slider.maxValue = 1
        slider.doubleValue = Double(player.volume)
        slider.target = self
        slider.action = #selector(volumeChanged)

        muteButton.target = self
        muteButton.action = #selector(volumeMute)

        downButton.target = self
        downButton.action = #selector(volumeDown)

        upButton.target = self
        upButton.action = #selector(volumeUp)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refresh),
                                               name: Notification.Name.PlayerVolumeChanged,
                                               object: nil)
        refresh()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func refresh() {
        slider.doubleValue = Double(player.volume)

        if player.isMuted {
            slider.isEnabled = false
            downButton.isEnabled = false
            upButton.isEnabled = false
            muteButton.state = .on
            muteButton.toolTip = "Unmute"
        } else {
            slider.isEnabled = true
            downButton.isEnabled = slider.doubleValue > slider.minValue
            upButton.isEnabled = slider.doubleValue < slider.maxValue
            muteButton.state = .off
            muteButton.toolTip = "Mute"
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func volumeChanged(_ sender: Any) {
        player.volume = Float(slider.doubleValue)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func volumeUp(_ sender: Any) {
        slider.doubleValue += 0.05
        volumeChanged(0)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func volumeDown(_ sender: Any) {
        slider.doubleValue -= 0.05
        volumeChanged(0)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func volumeMute(_ sender: Any) {
        player.isMuted = !player.isMuted
        volumeChanged(0)
    }
}
