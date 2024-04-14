//
//  PlayMenuItem.swift
//  Radiola
//
//  Created by Alex Sokolov on 14.04.2024.
//

import Cocoa

class PlayButtonImage: NSImageView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

/* ****************************************
 *
 * ****************************************/
class PlayMenuItem: NSMenuItem {
    private var controller = PlayItemController()

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(title: "", action: nil, keyEquivalent: "")
        controller.menuItem = self
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
fileprivate class PlayItemController: NSViewController {
    var playIcon = PlayButtonImage()
    var songLabel = Label()
    var stationLabel = Label()

    var menuItem: NSMenuItem?

    /* ****************************************
     *
     * ****************************************/
    override func viewDidLoad() {
        view = createView()

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
    private func createView() -> NSView {
        let res = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 45))

        playIcon.imageScaling = .scaleProportionallyUpOrDown

        songLabel.textColor = .labelColor
        songLabel.lineBreakMode = .byClipping
        stationLabel.font = NSFont.systemFont(ofSize: 13)
        songLabel.setFontWeight(.medium)

        stationLabel.textColor = .labelColor
        stationLabel.lineBreakMode = .byClipping
        stationLabel.font = NSFont.systemFont(ofSize: 11)

        res.addSubview(playIcon)
        res.addSubview(songLabel)
        res.addSubview(stationLabel)

        playIcon.translatesAutoresizingMaskIntoConstraints = false
        songLabel.translatesAutoresizingMaskIntoConstraints = false
        stationLabel.translatesAutoresizingMaskIntoConstraints = false

        playIcon.heightAnchor.constraint(equalToConstant: 18).isActive = true
        playIcon.widthAnchor.constraint(equalTo: playIcon.heightAnchor).isActive = true

        playIcon.leadingAnchor.constraint(equalTo: res.leadingAnchor, constant: 20).isActive = true
        playIcon.centerYAnchor.constraint(equalTo: res.centerYAnchor).isActive = true

        songLabel.leadingAnchor.constraint(equalTo: res.leadingAnchor, constant: 53).isActive = true
        songLabel.trailingAnchor.constraint(equalTo: res.trailingAnchor, constant: -20).isActive = true

        stationLabel.leadingAnchor.constraint(equalTo: songLabel.leadingAnchor).isActive = true
        stationLabel.trailingAnchor.constraint(equalTo: songLabel.trailingAnchor).isActive = true

        songLabel.topAnchor.constraint(equalTo: res.topAnchor, constant: 7).isActive = true
        stationLabel.topAnchor.constraint(equalTo: songLabel.bottomAnchor, constant: 4).isActive = true

        return res
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func toggle() {
        player.toggle()
        menuItem?.menu?.cancelTracking()
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
                playIcon.image = NSImage(systemSymbolName: NSImage.Name("play.fill"), accessibilityDescription: "Play")
                playIcon.image?.isTemplate = true
                stationLabel.stringValue = player.stationName
                songLabel.stringValue = ""

            case Player.Status.connecting:
                playIcon.image = NSImage(systemSymbolName: NSImage.Name("pause.fill"), accessibilityDescription: "Pause")
                playIcon.image?.isTemplate = true
                stationLabel.stringValue = player.stationName
                songLabel.stringValue = "Connecting...".tr(withComment: "Station label text")

            case Player.Status.playing:
                playIcon.image = NSImage(systemSymbolName: NSImage.Name("pause.fill"), accessibilityDescription: "Pause")
                playIcon.image?.isTemplate = true
                stationLabel.stringValue = player.stationName
                songLabel.stringValue = player.songTitle
        }
    }
}
