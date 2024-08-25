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
class StatusBarController: NSObject {
    private let appState = AppState.shared
    let menuItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menuPrefix = "  "
    private let icon = StatusBarIcon(size: 16)

    private var mouseDownMonitor: Any?
    private var mouseUpMonitor: Any?
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

        mouseDownMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown], handler: mouseDown)
        mouseUpMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp, .otherMouseUp], handler: mouseUp)
        scrollWheelMonitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel], handler: scrollWheel)

        playerStatusChanged()
    }

    /* ****************************************
     *
     * ****************************************/
    deinit {
        if let monitor = mouseDownMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = mouseUpMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = scrollWheelMonitor { NSEvent.removeMonitor(monitor) }
    }

    /* ****************************************
     *
     * ****************************************/
    private func actionType(_ event: NSEvent) -> MouseButtonAction? {
        guard let btn = MouseButton(rawValue: event.buttonNumber) else { return nil }

        if event.modifierFlags.contains(.control) {
            return MouseButtonAction.showMenu
        }

        return settings.mouseAction(forButton: btn)
    }

    /* ****************************************
     *
     * ****************************************/
    private func mouseDown(_ event: NSEvent) -> NSEvent? {
        if event.window != menuItem.button?.window {
            return event
        }

        let action = actionType(event)

        switch action {
            case .showMenu:
                menuItem.menu = buildMenu()
                return NSEvent.mouseEvent(
                    with: .leftMouseDown,
                    location: event.locationInWindow,
                    modifierFlags: event.modifierFlags,
                    timestamp: event.timestamp,
                    windowNumber: event.windowNumber,
                    context: nil,
                    eventNumber:
                    event.eventNumber,
                    clickCount: event.clickCount,
                    pressure: event.pressure)

            case .playPause:
                player.toggle()
                return nil

            case .showMainWindow:
                _ = StationsWindow.show()
                return nil

            case .showHistory:
                _ = HistoryWindow.show()
                return nil

            case .mute:
                player.isMuted = !player.isMuted
                return nil

            case nil:
                return event
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func mouseUp(_ event: NSEvent) -> NSEvent? {
        if event.window != menuItem.button?.window {
            return event
        }

        let action = actionType(event)

        switch action {
            case .showMenu:
                return NSEvent.mouseEvent(
                    with: .leftMouseUp,
                    location: event.locationInWindow,
                    modifierFlags: event.modifierFlags,
                    timestamp: event.timestamp,
                    windowNumber: event.windowNumber,
                    context: nil,
                    eventNumber: event.eventNumber,
                    clickCount: event.clickCount,
                    pressure: event.pressure)

            case .playPause:
                return nil

            case .showMainWindow:
                return nil

            case .showHistory:
                return nil

            case .mute:
                return nil

            case nil:
                return event
        }
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
    @objc func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let playItem = PlayMenuItem()
        playItem.target = self
        playItem.isEnabled = true
        menu.addItem(playItem)

        if settings.showVolumeInMenu {
            menu.addItem(NSMenuItem.separator())
            let volumeItem = VolumeMenuItem()
            menu.addItem(volumeItem)
        }

        if settings.showMuteInMenu {
            let item = NSMenuItem(
                title: player.isMuted ? "Unmute" : "Mute",
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
            title: "Open Radiola",
            action: #selector(AppDelegate.showStationView(_:)),
            keyEquivalent: "r"))

        menu.addItem(NSMenuItem(
            title: "History...",
            action: #selector(AppDelegate.showHistory(_:)),
            keyEquivalent: "y"))

        menu.addItem(NSMenuItem(
            title: "Settings...",
            action: #selector(AppDelegate.showPreferences(_:)),
            keyEquivalent: ","))

        menu.addItem(NSMenuItem(
            title: "Quit".tr,
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"))

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
        menu.addItem(NSMenuItem(title: "Favorite stations".tr, action: nil, keyEquivalent: ""))

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

        menu.addItem(NSMenuItem(title: "Favorite stations".tr, action: nil, keyEquivalent: ""))
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

        menu.addItem(NSMenuItem(title: "Favorite stations".tr, action: nil, keyEquivalent: ""))
        for list in AppState.shared.localStations {
            build(items: list.items, menu: menu, prefix: menuPrefix)
        }
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
                    "Connecting...".tr(withComment: "Tooltip text")

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
