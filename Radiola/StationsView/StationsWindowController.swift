//
//  StationWindowController.swift
//  Radiola
//
//  Created by Alex Sokolov on 03.11.2020.
//  Copyright © 2020 Alex Sokolov. All rights reserved.
//

import Cocoa

class StationsWindowController: NSWindowController {
    let player : Player? = (NSApp.delegate as? AppDelegate)?.player
    
    @IBOutlet weak var playButton: NSToolbarItem!
    
    
    @IBAction func playButtonClicked(_ sender: Any) {
        player?.toggle()
    }
    
    
    override func windowDidLoad() {
        super.windowDidLoad()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerStatusChanged),
                                               name: Notification.Name.PlayerStatusChanged,
                                               object: nil)
        playerStatusChanged()
    }
    
    @objc func playerStatusChanged() {
        if (player?.status == Player.Status.playing) {
            playButton.image = NSImage(named:NSImage.Name("NSTouchBarPauseTemplate"))
            playButton.label = "Pause".tr(withComment: "Toolbar button label")
            playButton.toolTip = "Pause".tr(withComment: "Toolbar button toolTip")
        }
        else {
            playButton.image = NSImage(named:NSImage.Name("NSTouchBarPlayTemplate"))
            playButton.label = "Play".tr(withComment: "Toolbar button label")
            playButton.toolTip = "Play".tr(withComment: "Toolbar button toolTip")
        }
    }
}

