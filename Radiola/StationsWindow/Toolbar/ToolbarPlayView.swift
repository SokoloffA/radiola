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

    /* ****************************************
     *
     * ****************************************/
    override func viewDidLoad() {
        super.viewDidLoad()

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
                songLabel.stringValue = "Super Song"

            case Player.Status.connecting:
                stationLabel.stringValue = player.stationName
                songLabel.stringValue = "Connecting...".tr(withComment: "Station label text")

            case Player.Status.playing:
                stationLabel.stringValue = player.stationName
                songLabel.stringValue = player.title
        }

        switch player.status {
            case Player.Status.paused:
                playButton.image = NSImage(named: NSImage.Name("NSTouchBarPlayTemplate"))
                playButton.image?.isTemplate = true
                playButton.toolTip = "Play".tr(withComment: "Toolbar button toolTip")

            case Player.Status.connecting:
                playButton.image = NSImage(named: NSImage.Name("NSTouchBarPauseTemplate"))
                playButton.image?.isTemplate = true
                playButton.toolTip = "Pause".tr(withComment: "Toolbar button toolTip")

            case Player.Status.playing:
                playButton.image = NSImage(named: NSImage.Name("NSTouchBarPauseTemplate"))
                playButton.image?.isTemplate = true
                playButton.toolTip = "Pause".tr(withComment: "Toolbar button toolTip")
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func togglePlay() {
        player.toggle()
    }
}
