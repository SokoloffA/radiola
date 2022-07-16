//
//  PlayItemController.swift
//  Radiola
//
//  Created by Alex Sokolov on 16.07.2022.
//

import Cocoa

class PlayItemController: NSViewController {

    @IBOutlet var playIcon: NSImageView!
    @IBOutlet var songLabel: NSTextField!
    @IBOutlet var stationLabel: NSTextField!

    weak var parentMenu: NSMenu?

    init() {
        super.init(nibName: "PlayItemController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refresh),
                                               name: Notification.Name.PlayerStatusChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refresh),
                                               name: Notification.Name.PlayerMetadataChanged,
                                               object: nil)

        refresh()
    }

    override func mouseUp(with theEvent: NSEvent) {
        player.toggle()
        parentMenu?.cancelTracking()
    }

    override func rightMouseUp(with event: NSEvent) {
        player.toggle()
        parentMenu?.cancelTracking()
    }

    @objc private func refresh() {
        switch player.status {
        case Player.Status.paused:
            playIcon.image = NSImage(named: NSImage.Name("PlayMenu"))
            playIcon.image?.isTemplate = true
            stationLabel.stringValue = player.station.name
            songLabel.stringValue = ""

        case Player.Status.connecting:
            playIcon.image = NSImage(named: NSImage.Name("PauseMenu"))
            playIcon.image?.isTemplate = true
            stationLabel.stringValue = player.station.name
            songLabel.stringValue = "Connecting...".tr(withComment: "Station label text")

        case Player.Status.playing:
            playIcon.image = NSImage(named: NSImage.Name("PauseMenu"))
            playIcon.image?.isTemplate = true
            stationLabel.stringValue = player.station.name
            songLabel.stringValue = player.title
        }
    }
}
