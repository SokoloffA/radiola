//
//  Player.swift
//  Radiola
//
//  Created by Alex Sokolov on 23.05.2020.
//  Copyright © 2020 Alex Sokolov. All rights reserved.
//

import AVFoundation
import Cocoa
import Foundation

var player = Player()

class Player: NSObject, AVPlayerItemMetadataOutputPushDelegate {
    var station: Station?
    public var songTitle = String()
    public var stationName: String { station?.title ?? "" }

    public enum Status {
        case paused
        case connecting
        case playing
    }

    struct HistoryRecord {
        var song: String = ""
        var station: String = ""
        var date: Date = Date()
    }

    public var status = Status.paused
    public var history: [HistoryRecord] = []

    private var playerItemContext = 0
    private var player: AVPlayer!
    private var playerItem: AVPlayerItem?
    private var asset: AVAsset!
    private var timer: Timer?
    private let connectDelay = 15.0

    /* ****************************************
     *
     * ****************************************/
    var volume: Float {
        get { player.volume }
        set {
            let vol = max(0, min(1, newValue))

            if player.volume != vol {
                player.volume = vol
                settings.volumeLevel = newValue
                NotificationCenter.default.post(name: Notification.Name.PlayerVolumeChanged, object: nil)
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    var isMuted: Bool {
        get { player.isMuted }
        set {
            if player.isMuted != newValue {
                player.isMuted = newValue
                settings.volumeIsMuted = newValue
                NotificationCenter.default.post(name: Notification.Name.PlayerVolumeChanged, object: nil)
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    var audioDeviceUID: String? {
        get { player.audioOutputDeviceUniqueID }
        set {
            if player.audioOutputDeviceUniqueID == newValue {
                player.audioOutputDeviceUniqueID = newValue
                settings.audioDevice = newValue

                if isPlaying {
                    stop()
                    play()
                }
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    override init() {
        super.init()

        player = AVPlayer()
        player.volume = settings.volumeLevel
        player.isMuted = settings.volumeIsMuted
        player.audioOutputDeviceUniqueID = settings.audioDevice

        player.addObserver(self,
                           forKeyPath: #keyPath(AVPlayer.timeControlStatus),
                           options: [.old, .new],
                           context: &playerItemContext)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateAudioDevice),
                                               name: Notification.Name.AudioDeviceChanged,
                                               object: nil)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func play() {
        guard let station = station else { return }

        var u = URL(string: station.url)

        if u == nil {
            u = URL(string: station.url.replacingOccurrences(of: " ", with: "%20"))
        }

        if u == nil {
            Alarm.show(title: String(format: "Looks like \"%@\" is not a valid URL.", station.url))
            return
        }

        asset = AVAsset(url: u!)
        playerItem = AVPlayerItem(asset: asset)

        let metadataOutput = AVPlayerItemMetadataOutput(identifiers: nil)
        metadataOutput.setDelegate(self, queue: DispatchQueue.main)
        playerItem?.add(metadataOutput)

        player.replaceCurrentItem(with: playerItem)
        statusChenged(status: AVPlayer.TimeControlStatus.waitingToPlayAtSpecifiedRate)
        player.play()
        settings.lastStationUrl = station.url

        timer = Timer.scheduledTimer(
            timeInterval: connectDelay,
            target: self,
            selector: #selector(connectTimeout),
            userInfo: nil,
            repeats: false)
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
        guard let station = station else { return }

        if isPlaying {
            stop()
            return
        }

        if !station.url.isEmpty {
            play()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func switchStation(station: Station) {
        if self.station?.id == station.id && isPlaying {
            return
        }

        self.station = station
        play()
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
    @objc private func connectTimeout(timer: Timer) {
        if status == .connecting && timer == self.timer {
            stop()
        }
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
                songTitle = ""
                NotificationCenter.default.post(name: Notification.Name.PlayerMetadataChanged, object: nil, userInfo: ["title": ""])

            case AVPlayer.TimeControlStatus.playing:
                self.status = .playing

            default:
                self.status = .paused
                songTitle = ""
                NotificationCenter.default.post(name: Notification.Name.PlayerMetadataChanged, object: nil, userInfo: ["title": ""])
        }

        NotificationCenter.default.post(name: Notification.Name.PlayerStatusChanged, object: nil)
    }

    // ****************************************
    // Metadata
    // ****************************************
    func metadataOutput(_ output: AVPlayerItemMetadataOutput, didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup], from track: AVPlayerItemTrack?) {
        guard
            let item = groups.first?.items.first,
            let value = item.value(forKeyPath: #keyPath(AVMetadataItem.value))
        else {
            return
        }

        songTitle = "\(value)"
        addHistory()

        NotificationCenter.default.post(
            name: Notification.Name.PlayerMetadataChanged,
            object: nil,
            userInfo: ["title": songTitle])
    }

    /* ****************************************
     *
     * ****************************************/
    private func addHistory() {
        guard let station = station else { return }

        if history.last?.song == songTitle && history.last?.station == station.title {
            return
        }

        history.append(HistoryRecord(song: songTitle, station: station.title, date: Date()))
        if history.count > 100 {
            history.removeFirst(history.count - 100)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func updateAudioDevice() {
        let uid = player.audioOutputDeviceUniqueID

        if uid == nil {
            return
        }

        for d in AudioSytstem.devices() {
            if d.UID == uid {
                return
            }
        }

        audioDeviceUID = nil
    }

    /* ****************************************
     *
     * ****************************************/
    static func mouseWheelToVolume(delta: CGFloat) -> Float {
        let res = pow(abs(Float(delta) * 0.001), 1 / 2)
        return delta > 0 ? res : -res
    }

    /* ****************************************
     *
     * ****************************************/
    @objc public func toggleMute() {
        isMuted = !isMuted
    }

    /* ****************************************
     *
     * ****************************************/
    func incVolume() {
        volume += 0.05
    }

    /* ****************************************
     *
     * ****************************************/
    func decVolume() {
        volume -= 0.05
    }
}
