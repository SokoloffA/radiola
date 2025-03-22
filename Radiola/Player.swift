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

extension AVPlayer.TimeControlStatus {
    var description: String {
        switch self {
            case .paused: return "paused"
            case .waitingToPlayAtSpecifiedRate: return "waitingToPlayAtSpecifiedRate"
            case .playing: return "playing"
            @unknown default: return "unknown"
        }
    }
}

// MARK: - Player

var player = Player()

class Player: NSObject, AVPlayerItemMetadataOutputPushDelegate {
    var station: Station?
    public var songTitle = String()
    public var stationName: String { station?.title ?? "" }
    public var isFavoriteSong: Bool {
        get { getIsFavoriteSong() }
        set { setIsFavoriteSong(newValue) }
    }

    public enum Status {
        case paused
        case connecting
        case playing
    }

    public var status = Status.paused
    private var playerItemContext = 0
    private var player: AVPlayer?
    private var timer: Timer?
    private let connectDelay = 15.0

    /* ****************************************
     *
     * ****************************************/
    var volume: Float { didSet {
        player?.volume = max(0, min(1, volume))
        settings.volumeLevel = volume
        NotificationCenter.default.post(name: Notification.Name.PlayerVolumeChanged, object: nil)
    }}

    /* ****************************************
     *
     * ****************************************/
    var isMuted: Bool { didSet {
        player?.isMuted = isMuted
        settings.volumeIsMuted = isMuted
        NotificationCenter.default.post(name: Notification.Name.PlayerVolumeChanged, object: nil)
    }}

    /* ****************************************
     *
     * ****************************************/
    var audioDeviceUID: String? { didSet {
        settings.audioDevice = audioDeviceUID
        if let player = player {
            if player.audioOutputDeviceUniqueID != audioDeviceUID {
                player.audioOutputDeviceUniqueID = audioDeviceUID

                if isPlaying {
                    stop()
                    play()
                }
            }
        }
    }}

    /* ****************************************
     *
     * ****************************************/
    override init() {
        self.volume = settings.volumeLevel
        self.isMuted = settings.volumeIsMuted
        self.audioDeviceUID = settings.audioDevice

        super.init()

        debugAudioDevices()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func play() {
        guard let station = station else { return }

        var url = URL(string: station.url)

        if url == nil {
            url = URL(string: station.url.replacingOccurrences(of: " ", with: "%20"))
        }

        if url == nil {
            Alarm.show(title: String(format: NSLocalizedString("Looks like \"%@\" is not a valid URL.", comment: "Player error message. %@ is URL of station."), station.url))
            return
        }

        guard let url = url else {
            debug("Incorrect URL:", station.url)
            return
        }

        debug("Play \(station.url) \(url)")

        stop()

        let player = AVPlayer()
        player.volume = self.volume
        player.isMuted = self.isMuted
        player.audioOutputDeviceUniqueID = self.audioDeviceUID

        player.addObserver(self,
                           forKeyPath: #keyPath(AVPlayer.timeControlStatus),
                           options: [.old, .new],
                           context: &playerItemContext)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateAudioDevice),
                                               name: Notification.Name.AudioDeviceChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(failedToPlay),
                                               name: .AVPlayerItemFailedToPlayToEndTime,
                                               object: player.currentItem)

        self.player = player
        debugAudioDevices()

        let playerItem = AVPlayerItem(url: url)

        let metadataOutput = AVPlayerItemMetadataOutput(identifiers: nil)
        metadataOutput.setDelegate(self, queue: DispatchQueue.main)
        playerItem.add(metadataOutput)
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
        player?.pause()
        player = nil
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
        debug("Player status changed \(status.description) for \(station?.url ?? "nil")")

        if let error = player?.currentItem?.error {
            warning("Player: Loading or preparation error: \(error.localizedDescription)")
        }

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

        songTitle = cleanTrackMetadata(raw: "\(value)")
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
        AppState.shared.history.add(station: station, songTitle: songTitle)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func updateAudioDevice() {
        let uid = player?.audioOutputDeviceUniqueID

        debug("Audio device changed: current ID: \(uid ?? "nil")")
        if uid == nil {
            return
        }

        for d in AudioSytstem.devices() {
            if d.UID == uid {
                return
            }
        }

        debug("Change player device ID from \(uid ?? "nil") to nil")
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

    /* ****************************************
     *
     * ****************************************/
    private func getIsFavoriteSong() -> Bool {
        if status != .playing {
            return false
        }
        guard let station = station else { return false }
        guard let rec = AppState.shared.history.last else { return false }

        if rec.stationURL == station.url && rec.song == songTitle {
            return rec.isFavorite
        }

        return false
    }

    /* ****************************************
     *
     * ****************************************/
    private func setIsFavoriteSong(_ favorite: Bool) {
        if status != .playing {
            return
        }

        guard let rec = AppState.shared.history.last else { return }

        rec.isFavorite = favorite
        NotificationCenter.default.post(name: Notification.Name.PlayerMetadataChanged, object: nil, userInfo: ["title": songTitle])
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func failedToPlay(_ notification: Notification) {
        guard let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error else { return }
        warning("Player: Playing error : \(error.localizedDescription)")
    }

    /* ****************************************
     *
     * ****************************************/
    private func debugAudioDevices() {
        debug("Player audio device ID: \(player?.audioOutputDeviceUniqueID ?? "nil")")
        if let ID = AudioSytstem.defaultOutputDeviceID() {
            debug("System default device ID: \(ID)")
        } else {
            debug("System default device ID: ERROR")
        }

        debug("Available audio devices:")
        let devices = AudioSytstem.devices()
        for d in devices {
            debug("  * UID: \(d.UID)")
            debug("    name: \(d.name)")
            debug("    deviceID: \(d.deviceID)")
            debug("    manufacturer: \(d.manufacturer)")
            debug("    streamsInput: \(d.streamsInput)")
            debug("    streamsOutput: \(d.streamsOutput)")
            debug("    sampleRateInput: \(d.sampleRateInput)")
            debug("    sampleRateOutput: \(d.sampleRateOutput)")
            debug("")
        }
    }
}
