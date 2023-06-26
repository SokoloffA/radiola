//
//  MainIcon.swift
//  Radiola
//
//  Created by Alex Sokolov on 12.06.2023.
//

import Cocoa

class StatusBarIcon {
    var framesPerSecond = 8 { didSet { update() } }
    let size: Int
    var statusItem: NSStatusItem? { didSet { update(force: true) } }
    var playerStatus: Player.Status = .paused { didSet { update() } }
    var muted: Bool = false { didSet { update() } }

    private var images: [State: [NSImage]] = [:]
    private var frames: [NSImage] = []
    private var timer: Timer?
    private var currentFrame = 0
    private var state: State?

    private enum State {
        case paused
        case playing
        case connecting

        case pausedMuted
        case playingMuted
        case connectingMuted
    }

    /* ****************************************
     *
     * ****************************************/
    init(size: Int = 16) {
        self.size = size

        images[.paused] = loadImages(["StatusBarPause"])
        images[.playing] = loadImages(["StatusBarPlay"])
        images[.connecting] = loadImages([
            "Connecting-1",
            "Connecting-2",
            "Connecting-3",
            "Connecting-4",
            "Connecting-5",
            "Connecting-4",
            "Connecting-3",
            "Connecting-2",
        ])

        images[.pausedMuted] = loadImages(["StatusBarPauseMute"])
        images[.playingMuted] = loadImages(["StatusBarPlayMute"])
        images[.connectingMuted] = loadImages([
            "ConnectingMuted-1",
            "ConnectingMuted-2",
            "ConnectingMuted-3",
            "ConnectingMuted-4",
            "ConnectingMuted-5",
            "ConnectingMuted-4",
            "ConnectingMuted-3",
            "ConnectingMuted-2",
        ])

        update()
    }

    /* ****************************************
     *
     * ****************************************/
    private func getState() -> State {
        if !muted {
            switch playerStatus {
                case .paused: return .paused
                case .playing: return .playing
                case .connecting: return .connecting
            }
        } else {
            switch playerStatus {
                case .paused: return .pausedMuted
                case .playing: return .playingMuted
                case .connecting: return .connectingMuted
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func update(force: Bool = false) {
        print("update")
        let st = getState()
        if !force && state == st {
            return
        }
        state = st

        frames = images[st]!
        currentFrame = 0

        if frames.count > 1 {
            start(startFrame: 0)
        } else {
            stop()
        }

        changeIcon()
    }

    /* ****************************************
     *
     * ****************************************/
    private func loadImages(_ names: [String]) -> [NSImage] {
        var res: [NSImage] = []
        for name in names {
            guard let img = NSImage(named: NSImage.Name(name)) else { continue }
            img.size = NSSize(width: size, height: size)
            img.isTemplate = true
            res.append(img)
        }
        return res
    }

    /* ****************************************
     *
     * ****************************************/
    private func start(startFrame: Int) {
        if statusItem == nil {
            return
        }
        if timer == nil {
            currentFrame = startFrame
            timer = Timer.scheduledTimer(timeInterval: 1.0 / Double(framesPerSecond),
                                         target: self,
                                         selector: #selector(changeIcon),
                                         userInfo: nil,
                                         repeats: true)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func stop() {
        currentFrame = 0
        timer?.invalidate()
        timer = nil
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func changeIcon() {
        guard let item = statusItem else { return }
        let cnt = frames.count
        item.button?.image = frames[currentFrame]
        currentFrame = (currentFrame + 1) % cnt
    }
}
