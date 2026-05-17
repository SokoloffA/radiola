
//  PlayView.swift
//  Radiola
//
//  Created by Alex Sokolov on 09.05.2026.
//

import Cocoa

class PlayView: NSControl {
    let playButton = NSButton()
    let songLabel = Label()
    let stationLabel = Label()
    let onlyStationLabel = Label()
    private var hideSongWorkItem: DispatchWorkItem?

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(frame: .zero)

        addSubview(playButton)
        addSubview(songLabel)
        addSubview(stationLabel)
        addSubview(onlyStationLabel)

        playButton.contentTintColor = .selectedControlTextColor
        playButton.setContentHuggingPriority(NSLayoutConstraint.Priority(240) /* .defaultLow */, for: NSLayoutConstraint.Orientation.horizontal)
        playButton.bezelStyle = .regularSquare
        playButton.setButtonType(.momentaryPushIn)
        playButton.imagePosition = .imageLeft
        playButton.title = ""
        playButton.alignment = .center
        playButton.lineBreakMode = NSLineBreakMode.byTruncatingTail
        playButton.state = NSControl.StateValue.on
        playButton.isBordered = false
        playButton.imageScaling = .scaleNone
        playButton.font = NSFont.systemFont(ofSize: 24)
        playButton.image?.isTemplate = true
        playButton.keyEquivalent = " "
        playButton.keyEquivalentModifierMask = []

        songLabel.font = NSFont.boldSystemFont(ofSize: 13)
        songLabel.textColor = .controlTextColor
        songLabel.lineBreakMode = .byTruncatingMiddle
        songLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        songLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        songLabel.menu = ContextMenu(textField: songLabel)

        stationLabel.textColor = .secondaryLabelColor
        stationLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        stationLabel.lineBreakMode = .byTruncatingMiddle
        stationLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        stationLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stationLabel.menu = ContextMenu(textField: stationLabel)

        onlyStationLabel.textColor = stationLabel.textColor
        onlyStationLabel.lineBreakMode = .byClipping
        onlyStationLabel.font = NSFont.systemFont(ofSize: 14)
        onlyStationLabel.setFontWeight(.semibold)
        onlyStationLabel.lineBreakMode = .byTruncatingTail
        onlyStationLabel.usesSingleLineMode = true

        playButton.translatesAutoresizingMaskIntoConstraints = false
        songLabel.translatesAutoresizingMaskIntoConstraints = false
        stationLabel.translatesAutoresizingMaskIntoConstraints = false
        onlyStationLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            playButton.widthAnchor.constraint(equalToConstant: 42),
            playButton.heightAnchor.constraint(equalToConstant: 38),
            playButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            playButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            songLabel.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 8),
            songLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            songLabel.bottomAnchor.constraint(equalTo: centerYAnchor, constant: -1),
            songLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 151),

            stationLabel.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 8),
            stationLabel.trailingAnchor.constraint(equalTo: songLabel.trailingAnchor),
            stationLabel.topAnchor.constraint(equalTo: centerYAnchor, constant: 2),

            onlyStationLabel.leadingAnchor.constraint(equalTo: stationLabel.leadingAnchor),
            onlyStationLabel.trailingAnchor.constraint(equalTo: stationLabel.trailingAnchor),
            onlyStationLabel.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
        ])

        playButton.target = self
        playButton.action = #selector(togglePlay)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refresh),
                                               name: Notification.Name.PlayerStatusChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refresh),
                                               name: Notification.Name.PlayerMetadataChanged,
                                               object: nil)

        refrreshLabels()
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
    @objc private func refresh() {
        hideSongWorkItem?.cancel()

        if player.status == .playing && player.songTitle.isEmpty {
            let workItem = DispatchWorkItem { [weak self] in self?.refrreshLabels() }
            hideSongWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
        } else {
            refrreshLabels()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func refrreshLabels() {
        switch player.status {
            case Player.Status.paused:
                stationLabel.stringValue = player.stationName
                songLabel.stringValue = ""

            case Player.Status.connecting:
                stationLabel.stringValue = player.stationName
                songLabel.stringValue = NSLocalizedString("Connecting…", comment: "Station label text")

            case Player.Status.playing:
                stationLabel.stringValue = player.stationName
                songLabel.stringValue = player.songTitle
        }

        stationLabel.toolTip = stationLabel.stringValue
        songLabel.toolTip = songLabel.stringValue

        switch player.status {
            case Player.Status.paused:
                playButton.image = NSImage(named: NSImage.Name("NSTouchBarPlayTemplate"))
                playButton.image?.isTemplate = true
                playButton.toolTip = NSLocalizedString("Play", comment: "Toolbar button toolTip")

            case Player.Status.connecting:
                playButton.image = NSImage(named: NSImage.Name("NSTouchBarPauseTemplate"))
                playButton.image?.isTemplate = true
                playButton.toolTip = NSLocalizedString("Pause", comment: "Toolbar button toolTip")

            case Player.Status.playing:
                playButton.image = NSImage(named: NSImage.Name("NSTouchBarPauseTemplate"))
                playButton.image?.isTemplate = true
                playButton.toolTip = NSLocalizedString("Pause", comment: "Toolbar button toolTip")
        }

        onlyStationLabel.stringValue = stationLabel.stringValue

        onlyStationLabel.isVisible = songLabel.stringValue.isEmpty
        songLabel.isVisible = !onlyStationLabel.isVisible
        stationLabel.isVisible = !onlyStationLabel.isVisible
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func togglePlay() {
        player.toggle()
        sendAction(action, to: target)
    }
}
