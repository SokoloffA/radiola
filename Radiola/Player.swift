//
//  Player.swift
//  Radiola
//
//  Created by Alex Sokolov on 23.05.2020.
//  Copyright © 2020 Alex Sokolov. All rights reserved.
//

import AVFoundation
import Foundation

class Player: NSObject, AVPlayerItemMetadataOutputPushDelegate {
    var station: Station = Station(id: 0, name: "", url: "")
    public var title = String()

    public enum Status {
        case paused
        case connecting
        case playing
    }

    public var status = Status.paused

    private var playerItemContext = 0
    private var player: AVPlayer!
    private var playerItem: AVPlayerItem?
    var asset: AVAsset!

    override init() {
        super.init()

        player = AVPlayer()
        player.volume = 0.5

        player.addObserver(self,
                           forKeyPath: #keyPath(AVPlayer.timeControlStatus),
                           options: [.old, .new],
                           context: &playerItemContext)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func play() {
        guard let u = URL(string: station.url) else {
            return
        }

        asset = AVAsset(url: u)
        playerItem = AVPlayerItem(asset: asset)
        playerItem?.preferredForwardBufferDuration = 1

        let metadataOutput = AVPlayerItemMetadataOutput(identifiers: nil)
        metadataOutput.setDelegate(self, queue: DispatchQueue.main)
        playerItem?.add(metadataOutput)

        player.replaceCurrentItem(with: playerItem)
        player.play()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func stop() {
        player.pause()
        playerItem = nil
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

    /* ****************************************
     *
     * ****************************************/
    var isPlaying: Bool {
        return status != Status.paused
    }

    /* ****************************************
     *
     * ****************************************/
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
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
    }

    /* ****************************************
     *
     * ****************************************/
    private func statusChenged(status: AVPlayer.TimeControlStatus) {
        switch status {
        case AVPlayer.TimeControlStatus.waitingToPlayAtSpecifiedRate:
            self.status = .connecting
            title = ""
            NotificationCenter.default.post(name: Notification.Name.PlayerMetadataChanged, object: nil, userInfo: ["Title": ""])

        case AVPlayer.TimeControlStatus.playing:
            self.status = .playing

        default:
            self.status = .paused
            title = ""
            NotificationCenter.default.post(name: Notification.Name.PlayerMetadataChanged, object: nil, userInfo: ["Title": ""])
        }

        NotificationCenter.default.post(name: Notification.Name.PlayerStatusChanged, object: nil)
    }

    // ****************************************
    // Metadata
    func metadataOutput(_ output: AVPlayerItemMetadataOutput, didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup], from track: AVPlayerItemTrack?) {
        guard
            let item = groups.first?.items.first,
            let value = item.value(forKeyPath: #keyPath(AVMetadataItem.value))
        else {
            return
        }

        title = "\(value)"

        NotificationCenter.default.post(
            name: Notification.Name.PlayerMetadataChanged,
            object: nil,
            userInfo: ["Title": title])
    }
}
