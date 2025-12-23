//
//  AppDelegate.swift
//  Radiola
//
//  Created by Alex Sokolov on 26.05.2020.
//  Copyright © 2020 Alex Sokolov. All rights reserved.
//

import Cocoa

extension KeyboardShortcuts.Name {
    static let showMainWindow = Self("showMainWindow")
    static let showHistoryWindow = Self("showHistoryWindow")
    static let togglePlayPuse = Self("togglePlayPuse")
    static let showMainMenu = Self("showMainMenu")
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private let oplDirectoryName = "com.github.SokoloffA.Radiola/"
    private let oplFileName = "bookmarks.opml"
    private let audioSytstem = AudioSytstem()
    private let mediaKeys = MediaKeysController()
    private let mainMenuDelegate = MainMenuDelegate()

    @IBOutlet var pauseMenuItem: NSMenuItem!
    @IBOutlet var playMenuItem: NSMenuItem!
    @IBOutlet var checkForUpdatesMenuItem: NSMenuItem!

    private var statusBar: StatusBarController!
    private var argURL: URL?
    private var applicationLaunched: Bool = false

    /* ****************************************
     *
     * ****************************************/
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NotificationManager.shared.requestAuthorization { granted in
            debug(granted ? "Notifications allowed" : "Notifications denied")
        }

        NSApp.setActivationPolicy(.accessory)

        if let mainMenu = NSApp.mainMenu {
            for menuItem in mainMenu.items {
                menuItem.submenu?.delegate = mainMenuDelegate
            }
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(processError),
                                               name: Alarm.notificationName,
                                               object: nil)

        let dirName = URL(
            fileURLWithPath: oplDirectoryName,
            relativeTo: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first)

        if !FileManager.default.fileExists(atPath: dirName.absoluteString) {
            do {
                try FileManager.default.createDirectory(at: dirName, withIntermediateDirectories: true)
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerStatusChanged),
                                               name: Notification.Name.PlayerStatusChanged,
                                               object: nil)

        player.station = AppState.shared.lastStation()

        statusBar = StatusBarController()

        playMenuItem.target = player
        playMenuItem.action = #selector(Player.play)

        pauseMenuItem.target = player
        pauseMenuItem.action = #selector(Player.stop)

        checkForUpdatesMenuItem.target = updater
        checkForUpdatesMenuItem.action = #selector(Updater.checkForUpdates)

        KeyboardShortcuts.onKeyUp(for: .showMainWindow) { [self] in showStationView(nil) }
        KeyboardShortcuts.onKeyUp(for: .showHistoryWindow) { [self] in showHistory(nil) }
        KeyboardShortcuts.onKeyUp(for: .togglePlayPuse) { [self] in togglePlay(nil) }
        KeyboardShortcuts.onKeyUp(for: .showMainMenu) { [self] in showMainMenu(nil) }

        playerStatusChanged()

        if let url = argURL {
            playUrl(url)
        } else {
            if settings.playLastStation {
                debug("Auto play \(settings.lastStationUrl ?? "nil")")
                player.play()
            }
        }

        if settings.showMainWindowOnStartup {
            showStationView(nil)
        }

        applicationLaunched = true
    }

    /* ****************************************
     *
     * ****************************************/
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if settings.playLastStation {
            debug("Auto play \(settings.lastStationUrl ?? "nil")")
            player.play()
        }
        return true
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
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = clearURL(urls.first) else { return }

        if !applicationLaunched {
            argURL = url
            return
        }

        playUrl(url)
    }

    /* ****************************************
     * Remove radiola+ part from URL's scheme
     * ****************************************/
    private func clearURL(_ url: URL?) -> URL? {
        guard
            let url = url,
            var items = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let scheme = items.scheme
        else {
            return nil
        }

        let parts = scheme.split(separator: "+", maxSplits: 1)
        if parts.count == 2 {
            items.scheme = String(parts[1])
        }

        return items.url
    }

    /* ****************************************
     *
     * ****************************************/
    private func playUrl(_ url: URL) {
        debug("Play passed URL \(url)")

        var station: Station?

        station = AppState.shared.localStation(byURL: url.absoluteString)
        if station == nil {
            var title: String?

            if #available(macOS 13.0, *) {
                title = url.fragment()
            }

            if title == nil {
                title = url.absoluteString
            }

            station = OpmlStation(title: title ?? "", url: url.absoluteString)
        }

        player.station = station
        player.play()
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
    @objc func togglePlay(_ sender: NSMenuItem?) {
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
    @IBAction func showStationView(_ sender: Any?) {
        StationsWindow.show()
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func showMainMenu(_ sender: Any?) {
        statusBar.showMenu()
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func showHistory(_ sender: Any?) {
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
    @IBAction func showLogsWindow(_ sender: Any?) {
        LogsWindow.show()
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
    @objc private func processError(_ notification: Notification) {
        guard let alarm = notification.object as? Alarm else { return }

        NotificationManager.shared.postNotification(
            title: alarm.title,
            body: alarm.message ?? ""
        )
    }
}

// MARK: - [MainMenu] AppDelegate: NSUserInterfaceValidations

extension AppDelegate: NSUserInterfaceValidations {
    func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        switch item.action {
            case #selector(copySongToClipboard): return player.songTitle != ""

            default: return true
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func copySongToClipboard(_ sender: Any) {
        if player.songTitle != "" {
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([.string], owner: nil)
            pasteboard.setString(player.songTitle, forType: .string)
        }
    }
}
