//
//  ToolbarPlayView.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 30.08.2023.
//

import Cocoa

class ToolbarPlayView: NSViewController {
    @IBOutlet var playButton: NSButton!
    @IBOutlet var songLabel: NSTextField!
    @IBOutlet var stationLabel: NSTextField!
    private let onlyStationLabel = Label()

    /* ****************************************
     *
     * ****************************************/
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(onlyStationLabel)
        onlyStationLabel.textColor = stationLabel.textColor
        onlyStationLabel.lineBreakMode = .byClipping
        onlyStationLabel.font = NSFont.systemFont(ofSize: 14)
        onlyStationLabel.setFontWeight(.semibold)
        onlyStationLabel.lineBreakMode = .byTruncatingTail
        onlyStationLabel.usesSingleLineMode = true
        onlyStationLabel.translatesAutoresizingMaskIntoConstraints = false

        onlyStationLabel.leadingAnchor.constraint(equalTo: stationLabel.leadingAnchor).isActive = true
        onlyStationLabel.trailingAnchor.constraint(equalTo: stationLabel.trailingAnchor).isActive = true
        onlyStationLabel.centerYAnchor.constraint(equalTo: playButton.centerYAnchor).isActive = true

        songLabel.lineBreakMode = .byTruncatingMiddle
        songLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        songLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        songLabel.menu = ContextMenu(textField: songLabel)

        stationLabel.lineBreakMode = .byTruncatingMiddle
        stationLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        stationLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stationLabel.menu = ContextMenu(textField: stationLabel)

        playButton.setContentHuggingPriority(NSLayoutConstraint.Priority(240) /* .defaultLow */, for: NSLayoutConstraint.Orientation.horizontal)
        playButton.bezelStyle = NSButton.BezelStyle.regularSquare
        playButton.setButtonType(NSButton.ButtonType.momentaryPushIn)
        playButton.imagePosition = NSControl.ImagePosition.imageOnly
        playButton.alignment = NSTextAlignment.center
        playButton.lineBreakMode = NSLineBreakMode.byTruncatingTail
        playButton.state = NSControl.StateValue.on
        playButton.isBordered = false
        playButton.imageScaling = NSImageScaling.scaleNone
        playButton.font = NSFont.systemFont(ofSize: 24)
        playButton.image?.isTemplate = true
        playButton.target = self
        playButton.action = #selector(togglePlay)
        playButton.keyEquivalent = " "
        playButton.keyEquivalentModifierMask = []

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
    @objc private func refresh() {
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
    @objc private func togglePlay() {
        player.toggle()
    }
}
