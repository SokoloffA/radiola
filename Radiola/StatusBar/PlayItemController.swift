//
//  PlayItemController.swift
//  Radiola
//
//  Created by Alex Sokolov on 16.07.2022.
//

import Cocoa
class PlayButtonImage: NSImageView {
    weak var playItemController: PlayItemController?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    override func mouseUp(with theEvent: NSEvent) {
        playItemController?.toggle()
    }
}

/* ****************************************
 *
 * ****************************************/
class PlayMenuItem: NSMenuItem {
    public var controller: PlayItemController!

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(title: "", action: nil, keyEquivalent: "")
        controller = PlayItemController(menuItem: self)
        view = controller.view
    }

    /* ****************************************
     *
     * ****************************************/
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/* ****************************************
 *
 * ****************************************/
class PlayItemController: NSViewController {
    @IBOutlet var playIcon: PlayButtonImage!
    @IBOutlet var songLabel: NSTextField!
    @IBOutlet var stationLabel: NSTextField!

    private let menuItem: NSMenuItem

    /* ****************************************
     *
     * ****************************************/
    init(menuItem: NSMenuItem) {
        self.menuItem = menuItem
        super.init(nibName: "PlayItemController", bundle: nil)
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
        playIcon.playItemController = self

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

    /* ****************************************
     *
     * ****************************************/
    @objc func toggle() {
        player.toggle()
        menuItem.menu?.cancelTracking()
    }

    /* ****************************************
     *
     * ****************************************/
    override func mouseUp(with theEvent: NSEvent) {
        toggle()
    }

    /* ****************************************
     *
     * ****************************************/
    override func rightMouseUp(with event: NSEvent) {
        toggle()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func refresh() {
        switch player.status {
            case Player.Status.paused:
                playIcon.image = NSImage(named: NSImage.Name("PlayMenu"))
                playIcon.image?.isTemplate = true
                stationLabel.stringValue = player.stationName
                songLabel.stringValue = ""

            case Player.Status.connecting:
                playIcon.image = NSImage(named: NSImage.Name("PauseMenu"))
                playIcon.image?.isTemplate = true
                stationLabel.stringValue = player.stationName
                songLabel.stringValue = "Connecting...".tr(withComment: "Station label text")

            case Player.Status.playing:
                playIcon.image = NSImage(named: NSImage.Name("PauseMenu"))
                playIcon.image?.isTemplate = true
                stationLabel.stringValue = player.stationName
                songLabel.stringValue = player.songTitle
        }
    }
}
