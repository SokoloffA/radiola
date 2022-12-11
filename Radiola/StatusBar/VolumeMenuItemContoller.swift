//
//  VolumeMenuItem.swift
//  Radiola
//
//  Created by Alex Sokolov on 03.12.2022.
//

import Cocoa

/* ****************************************
 *
 * ****************************************/
class VolumeMenuItem: NSMenuItem {
    public let controller: VolumeMenuItemContoller!

    init() {
        controller = VolumeMenuItemContoller()
        super.init(title: "", action: nil, keyEquivalent: "")
        view = controller.view
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/* ****************************************
 *
 * ****************************************/
class VolumeMenuItemContoller: NSViewController {
    weak var parentMenu: NSMenu?

    @IBOutlet var volumeDownButton: NSButton!
    @IBOutlet var volumeUpButton: NSButton!
    @IBOutlet var volumeControl: NSSlider!

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(nibName: "VolumeMenuItem", bundle: nil)
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

        volumeControl.minValue = 0
        volumeControl.maxValue = 1

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refresh),
                                               name: Notification.Name.PlayerVolumeChanged,
                                               object: nil)

        refresh()
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func volumeChanged(_ sender: Any) {
        player.volume = Float(volumeControl.doubleValue)
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func volumeDown(_ sender: Any) {
        volumeControl.doubleValue -= 0.05
        volumeChanged(self)
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func volumeUp(_ sender: Any) {
        volumeControl.doubleValue += 0.05
        volumeChanged(self)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func refresh() {
        volumeControl.doubleValue = Double(player.volume)

        if player.isMuted {
            volumeControl.isEnabled = false
            volumeDownButton.isEnabled = false
            volumeUpButton.isEnabled = false
        } else {
            volumeDownButton.isEnabled = volumeControl.doubleValue > volumeControl.minValue
            volumeUpButton.isEnabled = volumeControl.doubleValue < volumeControl.maxValue
        }
    }
}
