//
//  PlayItemView.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 09.03.2021.
//  Copyright © 2021 Alex Sokolov. All rights reserved.
//

import Cocoa

class PlayItemView: NSView {

    private var nibView: NSView?
    let player : Player? = (NSApp.delegate as? AppDelegate)?.player
    
    @IBOutlet weak var songLabel: NSTextField!
    @IBOutlet weak var stationLabel: NSTextField!
    @IBOutlet weak var playButton: NSButton!

    private func loadNib() -> NSView? {
        let nibName = NSNib.Name(stringLiteral: "PlayItemView")
        var topLevelArray: NSArray? = nil
        Bundle.main.loadNibNamed(NSNib.Name(nibName), owner: self, topLevelObjects: &topLevelArray)
        guard let results = topLevelArray else { return nil }
        let views = Array<Any>(results).filter { $0 is NSView }
        return views.last as? NSView
    }

    init() {
        super.init(frame: NSRect.zero)
        // Load and set constraints ......................
        nibView = loadNib()
    
        guard let nibView = nibView else {return }
        self.addSubview(nibView)

        nibView.translatesAutoresizingMaskIntoConstraints = false
        self.translatesAutoresizingMaskIntoConstraints = false
        self.frame = nibView.frame
        
        nibView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        nibView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true

        nibView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        nibView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        // ...............................................
        
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

    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBAction func togglePlayPause(_ sender: Any) {
        print(player != nil)
        player?.toggle()
    }
    
    @objc func playerStatusChanged() {
        guard let player = player else { return }
        
        if (player.status == Player.Status.playing) {
            playButton.image = NSImage(named:NSImage.Name("NSTouchBarPauseTemplate"))
            playButton.toolTip = "Pause".tr(withComment: "Toolbar button toolTip")
        }
        else {
            playButton.image = NSImage(named:NSImage.Name("NSTouchBarPlayTemplate"))
            playButton.toolTip = "Play".tr(withComment: "Toolbar button toolTip")
        }
    }
    
    @objc func updateLabels() {
        guard let player = player else {
            songLabel.stringValue = ""
            stationLabel.stringValue = ""
            return
        }
        print("UPDATE LABELS", player.isPlaying, player.station.name, player.title)
        stationLabel.stringValue = player.station.name
        songLabel.stringValue = player.isPlaying ? player.title : "";
    }
    
}
