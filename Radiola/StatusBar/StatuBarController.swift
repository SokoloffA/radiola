//
//  StatuBarController.swift
//  Radiola
//
//  Created by Alex Sokolov on 27.11.2022.
//

import Cocoa

/* ****************************************
 *
 * ****************************************/
class StatusBarController: NSObject, NSMenuDelegate {
    private let appState = AppState.shared
    let menuItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menuPrefix = "  "
    private let icon = StatusBarIcon(size: 16)

    private var middleMouseMonitor: Any?
    private var scrollWheelMonitor: Any?

    /* ****************************************
     *
     * ****************************************/
    override init() {
        super.init()
        icon.statusItem = menuItem
        icon.framesPerSecond = 8
        icon.playerStatus = player.status
        icon.muted = player.isMuted

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerStatusChanged),
                                               name: Notification.Name.PlayerStatusChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateTooltip),
                                               name: Notification.Name.PlayerMetadataChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerVolumeChanged),
                                               name: Notification.Name.PlayerVolumeChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateTooltip),
                                               name: Notification.Name.SettingsChanged,
                                               object: nil)

        menuItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp, .otherMouseUp])
        menuItem.button?.target = self
        menuItem.button?.action = #selector(leftRightMouseAction)
        middleMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.otherMouseDown, .otherMouseUp], handler: middleMouseDown)

        playerStatusChanged()
    }

    /* ****************************************
     *
     * ****************************************/
    deinit {
        if let monitor = middleMouseMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = scrollWheelMonitor { NSEvent.removeMonitor(monitor) }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func leftRightMouseAction() {
        if let event = NSApp.currentEvent {
            processEvent(event)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func middleMouseDown(_ event: NSEvent) -> NSEvent? {
        menuItem.button?.highlight(event.type == .otherMouseDown)

        if event.type == .otherMouseDown {
            processEvent(event)
        }
        return event
    }

    /* ****************************************
     *
     * ****************************************/
    private func scrollWheel(_ event: NSEvent) -> NSEvent? {
        if event.window != menuItem.button?.window {
            return event
        }

        if settings.mouseWheelAction != MouseWheelAction.nothing {
            var vol = Player.mouseWheelToVolume(delta: event.scrollingDeltaY)
            if event.isDirectionInvertedFromDevice {
                vol = -vol
            }

            player.volume += vol
        }

        return event
    }

    /* ****************************************
     *
     * ****************************************/
    private func processEvent(_ event: NSEvent) {
        guard let action = actionType(event) else { return }

        switch action {
            case .showMenu:
                menuItem.popUpMenu(buildMenu())
                break

            case .playPause:
                player.toggle()

            case .showMainWindow:
                _ = StationsWindow.show()

            case .showHistory:
                _ = HistoryWindow.show()

            case .mute:
                player.isMuted = !player.isMuted
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func actionType(_ event: NSEvent) -> MouseButtonAction? {
        guard let mouseButton = MouseButton(rawValue: event.buttonNumber) else { return nil }

        if event.modifierFlags.contains(.control) {
            return MouseButtonAction.showMenu
        }

        return settings.mouseAction(forButton: mouseButton)
    }

    /* ****************************************
     *
     * ****************************************/
    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let playItem = PlayMenuItem()
        playItem.target = self
        playItem.isEnabled = true
        menu.addItem(playItem)

        if settings.showVolumeInMenu {
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: NSLocalizedString("Volume", comment: "Status bar menu item"), action: nil, keyEquivalent: ""))
            let volumeItem = VolumeMenuItem(showMuteButton: settings.showMuteInMenu)
            menu.addItem(volumeItem)
        }

        if settings.showMuteInMenu && !settings.showVolumeInMenu {
            menu.addItem(NSMenuItem.separator())
            let item = NSMenuItem(
                title: player.isMuted ?
                    NSLocalizedString("Unmute", comment: "Status bar menu Item") :
                    NSLocalizedString("Mute", comment: "Status bar menu Item"),
                action: #selector(Player.toggleMute),
                keyEquivalent: "m")
            item.target = player
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        switch settings.favoritesMenuType {
            case .flat: buildFlatFavoritesMenu(menu: menu)
            case .margin: buildMarginFavoritesMenu(menu: menu)
            case .submenu: buildSubmenuFavoritesMenu(menu: menu)
        }

        if settings.showCopyToClipboardInMenu {
            menu.addItem(NSMenuItem.separator())

            menu.addItem(NSMenuItem(
                title: "Copy song title and artist",
                action: #selector(AppDelegate.copySongToClipboard(_:)),
                keyEquivalent: "c"))
        }

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: NSLocalizedString("Open Radiola…", comment: "Status bar menu item"),
            action: #selector(AppDelegate.showStationView(_:)),
            keyEquivalent: "r"))

        menu.addItem(NSMenuItem(
            title: NSLocalizedString("History…", comment: "Status bar menu item"),
            action: #selector(AppDelegate.showHistory(_:)),
            keyEquivalent: "y"))

        menu.addItem(NSMenuItem(
            title: NSLocalizedString("Settings…", comment: "Status bar menu item"),
            action: #selector(AppDelegate.showPreferences(_:)),
            keyEquivalent: ","))

        menu.addItem(NSMenuItem(
            title: NSLocalizedString("Quit", comment: "Status bar menu item"),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"))

        menu.delegate = self
        return menu
    }

    /* ****************************************
     *
     * ****************************************/
    private func createStationMenuItem(_ station: Station, prefix: String = "") -> NSMenuItem {
        let res = NSMenuItem(
            title: prefix + station.title,
            action: #selector(stationClicked(_:)),
            keyEquivalent: "")

        res.target = self
        res.representedObject = station

        return res
    }

    /* ****************************************
     *
     * ****************************************/
    func buildFlatFavoritesMenu(menu: NSMenu) {
        menu.addItem(NSMenuItem(title: NSLocalizedString("Favorite stations", comment: "Status bar menu item"), action: nil, keyEquivalent: ""))

        for station in appState.favoritesStations() {
            menu.addItem(createStationMenuItem(station))
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func buildMarginFavoritesMenu(menu: NSMenu) {
        func build(items: [StationItem], menu: NSMenu, prefix: String = "") {
            for item in items {
                if let station = item as? Station {
                    if station.isFavorite {
                        menu.addItem(createStationMenuItem(station, prefix: prefix))
                    }
                }

                if let group = item as? StationGroup {
                    let n = menu.numberOfItems

                    build(items: group.items, menu: menu, prefix: prefix + menuPrefix + "  ")
                    if menu.numberOfItems > n {
                        let groupItem = NSMenuItem(title: prefix + group.title, action: nil, keyEquivalent: "")
                        menu.insertItem(groupItem, at: n)
                    }
                }
            }
        }

        menu.addItem(NSMenuItem(title: NSLocalizedString("Favorite stations", comment: "Status bar menu item"), action: nil, keyEquivalent: ""))
        for list in AppState.shared.localStations {
            build(items: list.items, menu: menu, prefix: menuPrefix)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func buildSubmenuFavoritesMenu(menu: NSMenu) {
        func build(items: [StationItem], menu: NSMenu, prefix: String = "") {
            for item in items {
                if let station = item as? Station {
                    if station.isFavorite {
                        menu.addItem(createStationMenuItem(station, prefix: prefix))
                    }
                }

                if let group = item as? StationGroup {
                    let subMenu = NSMenu()
                    build(items: group.items, menu: subMenu)
                    if subMenu.numberOfItems > 0 {
                        let subMenuItem = NSMenuItem(title: prefix + group.title, action: nil, keyEquivalent: "")
                        subMenuItem.submenu = subMenu
                        menu.addItem(subMenuItem)
                    }
                }
            }
        }

        menu.addItem(NSMenuItem(title: NSLocalizedString("Favorite stations", comment: "Status bar menu item"), action: nil, keyEquivalent: ""))
        for list in AppState.shared.localStations {
            build(items: list.items, menu: menu, prefix: menuPrefix)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func menuDidClose(_ menu: NSMenu) {
        menuItem.menu = nil
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func playerStatusChanged() {
        icon.playerStatus = player.status
        updateTooltip()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func playerVolumeChanged() {
        icon.muted = player.isMuted
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func updateTooltip() {
        if settings.showTooltip == false {
            menuItem.button?.toolTip = ""
            return
        }

        switch player.status {
            case Player.Status.paused:
                menuItem.button?.toolTip = player.stationName

            case Player.Status.connecting:
                menuItem.button?.toolTip =
                    player.stationName +
                    "\n⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯\n" +
                    NSLocalizedString("Connecting…", comment: "Tooltip text")

            case Player.Status.playing:
                menuItem.button?.toolTip =
                    player.songTitle +
                    "\n⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯\n" +
                    player.stationName
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func stationClicked(_ sender: NSMenuItem) {
        guard let station = sender.representedObject as? Station else { return }
        player.switchStation(station: station)
    }
}
