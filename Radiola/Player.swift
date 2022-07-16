//
//  Player.swift
//  Radiola
//
//  Created by Alex Sokolov on 23.05.2020.
//  Copyright © 2020 Alex Sokolov. All rights reserved.
//

import AVFoundation
import Foundation

var player = Player()

class Player: NSObject, AVPlayerItemMetadataOutputPushDelegate {
    var station: Station = Station(id: 0, name: "", url: "")
    public var title = String()

    public enum Status {
        case paused
        case connecting
        case playing
    }

    struct HistoryRecord  {
        var song : String
        var station : String
        var date : Date = Date()
    }
    
    public var status = Status.paused
    public var history : [HistoryRecord] = []
    
    private var playerItemContext = 0
    private var player: AVPlayer!
    private var playerItem: AVPlayerItem?
    private var asset: AVAsset!
    private let settings = UserDefaults.standard

    var volume: Float {
        get { return player.volume }

        set(value) {
            player.volume = value
            settings.set(value, forKey: "Volume")
        }
    }

    /* ****************************************
     *
     * ****************************************/
    override init() {
        super.init()

        player = AVPlayer()
        settings.register(defaults: ["Volume" : 0.5])
        player.volume = settings.float(forKey: "Volume")

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
        addHistory()
        
        NotificationCenter.default.post(
            name: Notification.Name.PlayerMetadataChanged,
            object: nil,
            userInfo: ["Title": title])
    }
    
    private func addHistory() {
        if history.last?.song == title && history.last?.station == station.name {
            return
        }
        
        history.append(HistoryRecord(song: title, station: station.name, date: Date()))
        if history.count > 100 {
            history.removeFirst(history.count - 100)
        }

        
//        history.insert(HistoryRecord(song: title, station: station.name, date: Date()), at: 0)
//        if history.count > 100 {
//            history.removeLast(history.count - 100)
//        }
     
    }
}
