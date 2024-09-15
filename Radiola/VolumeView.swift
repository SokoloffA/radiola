//
//  VolumeView.swift
//  Radiola
//
//  Created by Alex Sokolov on 15.09.2024.
//

import Cocoa

class VolumeView: NSView {
    var muteButton: NSButton?
    var downButton = ImageButton(systemSymbolName: "speaker.wave.1.fill", accessibilityDescription: "Decrease the volume")
    var upButton = ImageButton(systemSymbolName: "speaker.wave.3.fill", accessibilityDescription: "Increase the volume")
    var slider = ScrollableSlider()

    /* ****************************************
     *
     * ****************************************/
    init(showMuteButton: Bool) {
        if showMuteButton {
            muteButton = ImageButton(systemSymbolName: "speaker.slash.fill", accessibilityDescription: "Mute")
        }
        super.init(frame: NSRect())

        addSubview(muteButton)
        addSubview(downButton)
        addSubview(slider)
        addSubview(upButton)

        slider.controlSize = .small

        if let muteButton = muteButton {
            muteButton.translatesAutoresizingMaskIntoConstraints = false
            muteButton.centerYAnchor.constraint(equalTo: downButton.centerYAnchor).isActive = true
            muteButton.widthAnchor.constraint(equalToConstant: 16).isActive = true
            muteButton.heightAnchor.constraint(equalToConstant: 16).isActive = true

            muteButton.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1).isActive = true
        }

        downButton.translatesAutoresizingMaskIntoConstraints = false
        downButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        downButton.widthAnchor.constraint(equalToConstant: 16).isActive = true
        downButton.heightAnchor.constraint(equalToConstant: 16).isActive = true

        if let muteButton = muteButton {
            downButton.leadingAnchor.constraint(equalToSystemSpacingAfter: muteButton.trailingAnchor, multiplier: 1).isActive = true
        } else {
            downButton.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1).isActive = true
        }

        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.centerYAnchor.constraint(equalTo: downButton.centerYAnchor).isActive = true
        slider.leadingAnchor.constraint(equalToSystemSpacingAfter: downButton.trailingAnchor, multiplier: 1).isActive = true

        upButton.translatesAutoresizingMaskIntoConstraints = false
        upButton.centerYAnchor.constraint(equalTo: downButton.centerYAnchor).isActive = true
        upButton.widthAnchor.constraint(equalToConstant: 16).isActive = true
        upButton.heightAnchor.constraint(equalToConstant: 16).isActive = true
        upButton.leadingAnchor.constraint(equalToSystemSpacingAfter: slider.trailingAnchor, multiplier: 1).isActive = true
        trailingAnchor.constraint(equalToSystemSpacingAfter: upButton.trailingAnchor, multiplier: 1).isActive = true

        slider.minValue = 0
        slider.maxValue = 1
        slider.doubleValue = Double(player.volume)
        slider.target = self
        slider.action = #selector(volumeChanged)

        muteButton?.target = self
        muteButton?.action = #selector(volumeMute)

        downButton.isContinuous = true
        downButton.target = self
        downButton.action = #selector(volumeDown)
        downButton.toolTip = NSLocalizedString("Decrease the volume", comment: "Volume button tooltip")

        upButton.isContinuous = true
        upButton.target = self
        upButton.action = #selector(volumeUp)
        upButton.toolTip = NSLocalizedString("Increase the volume", comment: "Volume button tooltip")

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refresh),
                                               name: Notification.Name.PlayerVolumeChanged,
                                               object: nil)
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

    /* ****************************************
     *
     * ****************************************/
    @objc private func refresh() {
        slider.doubleValue = Double(player.volume)

        if player.isMuted {
            slider.isEnabled = false
            downButton.isEnabled = false
            upButton.isEnabled = false
            muteButton?.state = .on
            muteButton?.toolTip = NSLocalizedString("Unmute", comment: "Mute button tooltip")
        } else {
            slider.isEnabled = true
            downButton.isEnabled = slider.doubleValue > slider.minValue
            upButton.isEnabled = slider.doubleValue < slider.maxValue
            muteButton?.state = .off
            muteButton?.toolTip = NSLocalizedString("Mute", comment: "Mute button tooltip")
        }
    }
}
