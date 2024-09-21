//
//  PlayMenuItem.swift
//  Radiola
//
//  Created by Alex Sokolov on 14.04.2024.
//

import Cocoa

// MARK: - PlayMenuItem

class PlayMenuItem: NSMenuItem {
    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(title: "", action: nil, keyEquivalent: "")
        view = PlayItemView(menuItem: self)
    }

    /* ****************************************
     *
     * ****************************************/
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - PlayItemView

fileprivate class PlayItemView: NSView {
    var playIcon = PlayButtonImage()
    var songLabel = Label()
    var stationLabel = Label()
    var favoriteButton = FavButton()

    weak var menuItem: NSMenuItem?

    /* ****************************************
     *
     * ****************************************/
    init(menuItem: NSMenuItem) {
        self.menuItem = menuItem
        super.init(frame: NSRect(x: 0, y: 0, width: 360, height: 45))
        createView()

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
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /* ****************************************
     *
     * ****************************************/
    private func createView() {
        autoresizingMask = [.height, .width]

        addSubview(playIcon)
        addSubview(songLabel)
        addSubview(stationLabel)
        addSubview(favoriteButton)

        playIcon.imageScaling = .scaleProportionallyUpOrDown

        favoriteButton.image = NSImage(systemSymbolName: NSImage.Name("heart"), accessibilityDescription: "Mark current song as favorite")
        favoriteButton.alternateImage = NSImage(systemSymbolName: NSImage.Name("heart.fill"), accessibilityDescription: "Unmark current song as favorite")
        favoriteButton.target = self
        favoriteButton.action = #selector(markAsFavoriteSong)
        favoriteButton.toolTip = "Mark current song as favorite"

        songLabel.textColor = .labelColor
        songLabel.lineBreakMode = .byClipping
        stationLabel.font = NSFont.systemFont(ofSize: 13)
        songLabel.setFontWeight(.semibold)

        stationLabel.textColor = .labelColor
        stationLabel.lineBreakMode = .byClipping
        stationLabel.font = NSFont.systemFont(ofSize: 11)

        playIcon.translatesAutoresizingMaskIntoConstraints = false
        songLabel.translatesAutoresizingMaskIntoConstraints = false
        stationLabel.translatesAutoresizingMaskIntoConstraints = false
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false

        playIcon.heightAnchor.constraint(equalToConstant: 18).isActive = true
        playIcon.widthAnchor.constraint(equalTo: playIcon.heightAnchor).isActive = true

        playIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        playIcon.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        songLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 53).isActive = true
        songLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -10).isActive = true

        favoriteButton.centerYAnchor.constraint(equalTo: songLabel.centerYAnchor).isActive = true
        favoriteButton.widthAnchor.constraint(equalTo: favoriteButton.heightAnchor).isActive = true
        trailingAnchor.constraint(equalToSystemSpacingAfter: favoriteButton.trailingAnchor, multiplier: 1.0).isActive = true

        stationLabel.leadingAnchor.constraint(equalTo: songLabel.leadingAnchor).isActive = true
        stationLabel.trailingAnchor.constraint(equalTo: songLabel.trailingAnchor).isActive = true

        songLabel.topAnchor.constraint(equalTo: topAnchor, constant: 7).isActive = true
        stationLabel.topAnchor.constraint(equalTo: songLabel.bottomAnchor, constant: 4).isActive = true
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
    override func mouseUp(with event: NSEvent) {
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

        favoriteButton.state = player.isFavoriteSong ? .on : .off
        favoriteButton.isEnabled = player.status == .playing
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func markAsFavoriteSong() {
        player.isFavoriteSong = !player.isFavoriteSong
        refresh()
    }
}

// MARK: - PlayButtonImage

fileprivate class PlayButtonImage: NSImageView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

// MARK: - FavButton

fileprivate class FavButton: ImageButton {
    override func mouseUp(with event: NSEvent) {
        // Block the passing of mouse clicks to the parent even for the disabled state.
    }

    override func rightMouseUp(with event: NSEvent) {
        // Block the passing of mouse clicks to the parent even for the disabled state.
    }
}
