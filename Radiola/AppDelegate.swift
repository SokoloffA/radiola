//
//  AppDelegate.swift
//  Radiola
//
//  Created by Alex Sokolov on 26.05.2020.
//  Copyright © 2020 Alex Sokolov. All rights reserved.
//

import Cocoa

extension String {
    var tr: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}

extension String {
    func tr(withComment: String) -> String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: withComment)
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private let oplDirectoryName = "com.github.SokoloffA.Radiola/"
    private let oplFileName = "bookmarks.opml"
    private let audioSytstem = AudioSytstem()

    @IBOutlet var pauseMenuItem: NSMenuItem!
    @IBOutlet var playMenuItem: NSMenuItem!
    @IBOutlet var checkForUpdatesMenuItem: NSMenuItem!

    private var statusBar: StatusBarController!

    /* ****************************************
     *
     * ****************************************/
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let dirName = URL(
            fileURLWithPath: oplDirectoryName,
            relativeTo: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first)

        let fileName = URL(
            fileURLWithPath: oplDirectoryName + "/" + oplFileName,
            relativeTo: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first)

        if !FileManager.default.fileExists(atPath: dirName.absoluteString) {
            do {
                try FileManager.default.createDirectory(at: dirName, withIntermediateDirectories: true)
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        stationsStore.load(file: fileName)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerStatusChanged),
                                               name: Notification.Name.PlayerStatusChanged,
                                               object: nil)

        if let url = settings.lastStationUrl {
            player.station = stationsStore.station(byUrl: url)
        } else {
            player.station = stationsStore.favorites().first
        }

        statusBar = StatusBarController()

        playMenuItem.target = player
        playMenuItem.action = #selector(Player.play)

        pauseMenuItem.target = player
        pauseMenuItem.action = #selector(Player.stop)

        checkForUpdatesMenuItem.target = updater
        checkForUpdatesMenuItem.action = #selector(Updater.checkForUpdates)

        playerStatusChanged()

        if settings.playLastStation {
            #if DEBUG
                print(settings.lastStationUrl!)
            #endif
            player.play()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func startPlay(_ sender: NSMenuItem) {
        player.play()
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func stopPlay(_ sender: NSMenuItem) {
        player.stop()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func togglePlay(_ sender: NSMenuItem) {
        player.toggle()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func playerStatusChanged() {
        switch player.status {
            case Player.Status.paused:
                playMenuItem.isHidden = false
                pauseMenuItem.isHidden = true

            case Player.Status.connecting:
                playMenuItem.isHidden = true
                pauseMenuItem.isHidden = false

            case Player.Status.playing:
                playMenuItem.isHidden = true
                pauseMenuItem.isHidden = false
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func showStationView(_ sender: Any?) {
        _ = StationsWindow.show()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func showHistory(_ sender: Any?) {
        _ = HistoryWindow.show()
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func showPreferences(_ sender: Any) {
        _ = PreferencesWindow.show()
    }

    /* ****************************************
     *
     * ****************************************/
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        NSApp.setActivationPolicy(.accessory)
        return false
    }

    /* ****************************************
     *
     * ****************************************/
    private func needHandleMediaKey() -> Bool {
        switch settings.mediaKeysHandle {
            case .disable: return false
            case .enable: return true
            case .mainWindowActive: return StationsWindow.isActie()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func needHandlePrevNextMediaKey() -> Bool {
        if !needHandleMediaKey() { return false }
        if settings.mediaPrevNextKeyAction != .switchStation { return false }
        // if !player.isPlaying {return false}
        return true
    }

    private func switchStation(offset: Int) {
        guard let cur = player.station else { return }
        let favorites = stationsStore.favorites()
        if favorites.count < 2 { return }

        var n = favorites.firstIndex { $0.url == cur.url }
        if n != nil {
            n = (n! + offset) % favorites.count
        } else {
            n = 0
        }

        print(n, "of", favorites.count)
//        if n >= favorites.count { n = 0 }
//        if n
        print("Switch to ", favorites[n!].name)
        player.station = favorites[n!]
        player.play()
    }

    /* ****************************************
     *
     * ****************************************/
    func medialKeyPresset(keyCode: Int32, keyRepeat: Bool) {
        if !needHandleMediaKey() {
            return
        }

        if keyCode == NX_KEYTYPE_PLAY {
            player.toggle()
            return
        }

        if needHandlePrevNextMediaKey() {
            if keyCode == NX_KEYTYPE_NEXT {
                print("NEXT ====================")
                switchStation(offset: 1)
            }

            if keyCode == NX_KEYTYPE_PREVIOUS {
                print("PREV ===================")
                switchStation(offset: -1)
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func medialKeyReleased(keyCode: Int32) {
    }
}

class Application: NSApplication {
    /* ****************************************
     *
     * ****************************************/
    override func sendEvent(_ event: NSEvent) {
        if event.type == NSEvent.EventType.systemDefined && event.subtype.rawValue == 8 {
            let keyCode = ((event.data1 & 0xFFFF0000) >> 16)
            let keyFlags = (event.data1 & 0x0000FFFF)
            // Get the key state. 0xA is KeyDown, OxB is KeyUp
            let pressed = ((keyFlags & 0xFF00) >> 8) == 0xA
            let keyRepeat = (keyFlags & 0x1) != 0

            if pressed {
                guard let delegate = delegate as? AppDelegate else { return }
                delegate.medialKeyPresset(keyCode: Int32(keyCode), keyRepeat: keyRepeat)
            } else {
                guard let delegate = delegate as? AppDelegate else { return }
                delegate.medialKeyReleased(keyCode: Int32(keyCode))
            }
        }

        super.sendEvent(event)
    }
}
