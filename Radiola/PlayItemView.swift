//
//  PlayItemView.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 09.03.2021.
//  Copyright © 2021 Alex Sokolov. All rights reserved.
//

import Cocoa

class PlayItemView: NSView {
    var playButton: NSButton
    var songLabel: NSTextField
    var stationLabel: NSTextField
    var parent: NSMenu
    
    let player : Player? = (NSApp.delegate as? AppDelegate)?.player
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(parent: NSMenu) {
        self.parent = parent
        // Button .....................................
        playButton = NSButton()
        playButton.image = NSImage(named:NSImage.Name("NSTouchBarPlayTemplate"))
        playButton.bezelStyle = NSButton.BezelStyle.texturedSquare
        playButton.setButtonType(NSButton.ButtonType.momentaryPushIn)
        playButton.imagePosition = NSControl.ImagePosition.imageOnly
        playButton.alignment = NSTextAlignment.center
        playButton.lineBreakMode = NSLineBreakMode.byTruncatingTail
        playButton.state = NSControl.StateValue.on
        playButton.isBordered = false
        playButton.imageScaling = NSImageScaling.scaleProportionallyDown
        #if false
        playButton.wantsLayer = true
        playButton.layer?.backgroundColor = NSColor(red: 0, green: 0,blue: 0, alpha: 240).cgColor
        playButton.layer?.cornerRadius = 6
        #endif
        
        // Song label ...................................
        songLabel = NSTextField(labelWithString: "Simple Minds - She's A River")
        songLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
        songLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: NSFont.Weight.semibold)
        
        
        // Station label ................................
        stationLabel = NSTextField(labelWithString: "Radio Caroline 319 Gold [Hits from '60-'7-]")
        stationLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
//      stationLabel.lineBreakMode = NSLineBreakMode.byTruncatingMiddle
        
        super.init(frame: NSRect.zero)
        
        self.addSubview(playButton)
        self.addSubview(songLabel)
        self.addSubview(stationLabel)

        // Constrains .................................
        self.translatesAutoresizingMaskIntoConstraints = false
        songLabel.translatesAutoresizingMaskIntoConstraints = false
        stationLabel.translatesAutoresizingMaskIntoConstraints = false
        playButton.translatesAutoresizingMaskIntoConstraints = false
        
        songLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 7).isActive = true
        stationLabel.topAnchor.constraint(equalTo: songLabel.bottomAnchor, constant: 5).isActive = true
        self.bottomAnchor.constraint(equalTo: stationLabel.bottomAnchor, constant: 4).isActive = true
        
        songLabel.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 16).isActive = true
        stationLabel.leadingAnchor.constraint(equalTo: songLabel.leadingAnchor).isActive = true
        stationLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16).isActive = true
        songLabel.trailingAnchor.constraint(equalTo: stationLabel.trailingAnchor).isActive = true

        playButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 6).isActive = true
        playButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        playButton.heightAnchor.constraint(equalTo: playButton.widthAnchor).isActive = true
        playButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 14).isActive = true
        
        // :::::::::::::::::::::::::::::::::::::::::::::
        playButton.target = self
        playButton.action = #selector(PlayItemView.togglePlayPause)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerStatusChanged),
                                               name: Notification.Name.PlayerStatusChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateLabels),
                                               name: Notification.Name.PlayerMetadataChanged,
                                               object: nil)
        playerStatusChanged()
        updateLabels()
    }
    
    @objc func togglePlayPause(_ sender: Any) {
        player?.toggle()
        parent.cancelTracking()
    }
    
    @objc func playerStatusChanged() {
        guard let player = player else { return }
        
        switch player.status {
        case Player.Status.paused:
            playButton.image = NSImage(named:NSImage.Name("NSTouchBarPlayTemplate"))
            playButton.toolTip = "Play".tr(withComment: "Toolbar button toolTip")

        case Player.Status.connecting:
            playButton.image = NSImage(named:NSImage.Name("NSTouchBarPauseTemplate"))
            playButton.toolTip = "Pause".tr(withComment: "Toolbar button toolTip")

        case Player.Status.playing:
            playButton.image = NSImage(named:NSImage.Name("NSTouchBarPauseTemplate"))
            playButton.toolTip = "Pause".tr(withComment: "Toolbar button toolTip")
        }
        
        updateLabels()
    }
    
    @objc func updateLabels() {
        guard let player = player else {
            songLabel.stringValue = ""
            stationLabel.stringValue = ""
            return
        }

        switch player.status {
        case Player.Status.paused:
            stationLabel.stringValue = player.station.name
            songLabel.stringValue = "";

        case Player.Status.connecting:
            stationLabel.stringValue = player.station.name
            songLabel.stringValue = "Connecting...".tr(withComment: "Station label text")

        case Player.Status.playing:
            stationLabel.stringValue = player.station.name
            songLabel.stringValue = player.title;
        }
    }
}
			
