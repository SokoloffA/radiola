//
//  Player.swift
//  Radiola
//
//  Created by Alex Sokolov on 23.05.2020.
//  Copyright © 2020 Alex Sokolov. All rights reserved.
//

import Foundation
import AVFoundation

class Player: NSObject {
    var station: Station = Station(id: 0, name: "", url: "")
    
    private var playerItemContext = 0
    private var player : AVPlayer!
    private var playerItem: AVPlayerItem!
    var asset : AVAsset!
       
    /* ****************************************
     *
     * ****************************************/
    @objc func play() {
        guard let u = URL(string: self.station.url) else {
            return
        }
        
        asset = AVAsset(url: u)
        let assetKeys = [
            "playable",
            "hasProtectedContent"
        ]

        playerItem = AVPlayerItem(asset: asset,
                                  automaticallyLoadedAssetKeys: assetKeys)
        
        player = AVPlayer(playerItem: playerItem)
        // player.volume = 0.01

        player.addObserver(self,
                            forKeyPath: #keyPath(AVPlayer.timeControlStatus),
                            options: [.old, .new],
                            context: &playerItemContext)

        playerItem.addObserver(self,
                            forKeyPath: #keyPath(AVPlayerItem.timedMetadata),
                            options: NSKeyValueObservingOptions(),
                            context: &playerItemContext)

        playerItem.preferredForwardBufferDuration = 1
        player.play()
    }
    
    
    /* ****************************************
     *
     * ****************************************/
    @objc func stop() {
        self.player.pause()
    }
    
    
    /* ****************************************
     *
     * ****************************************/
    @objc func toggle() {
        if isPlaying {
            stop()
            return
        }
        
        if !station.isEmpty {
            play()
        }
    }
    
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {

        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayer.timeControlStatus) {
            if let statusNumber = change?[.newKey] as? NSNumber {
                self.statusChenged(status: AVPlayer.TimeControlStatus(rawValue: statusNumber.intValue)!)
            }
        }
        
        if keyPath == #keyPath(AVPlayerItem.timedMetadata) {
            if let metaData = playerItem.timedMetadata {
                metaDataReady(metadata: metaData)
            }
        }
    }
    
    private func statusChenged(status: AVPlayer.TimeControlStatus) {
        if (status == AVPlayer.TimeControlStatus.playing) {
            self.status = .playing
        } else {
            self.status = .paused
        }
        NotificationCenter.default.post(name: Notification.Name.PlayerStatusChanged, object: nil)
    }

    //****************************************
    // Metadata
    public var title = String()
    
    private func metaDataReady(metadata: [AVMetadataItem]) {
        for m in metadata {
            if m.commonKey == AVMetadataKey("title") {
                if let v = m.stringValue {
                    title = v
                    NotificationCenter.default.post(
                        name: Notification.Name.PlayerMetadataChanged,
                        object: nil,
                        userInfo: ["Title": v])
                }
            }
        }
    }
 
    
    public enum Status {
        case paused
        case playing
    }

    public var status = Status.paused
    var isPlaying: Bool { return status == Status.playing }
}
