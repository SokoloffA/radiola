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
    private let menuItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menuPrefix = "  "
    private let icon = StatusBarIcon(size: 16)

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

        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown], handler: mouseDown)
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp, .otherMouseUp], handler: mouseUp)
        NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel], handler: scrollWheel)

        playerStatusChanged()
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

        menu.addItem(NSMenuItem.separator())

        switch settings.favoritesMenuType {
            case .flat: buildFlatFavoritesMenu(menu: menu)
            case .margin: buildMarginFavoritesMenu(menu: menu)
            case .submenu: buildSubmenuFavoritesMenu(menu: menu)
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
            title: prefix + station.name,
            action: #selector(stationClicked(_:)),
            keyEquivalent: "")

        res.target = self
        res.tag = station.id

        return res
    }

    /* ****************************************
     *
     * ****************************************/
    func buildFlatFavoritesMenu(menu: NSMenu) {
        menu.addItem(NSMenuItem(title: "Favorite stations".tr, action: nil, keyEquivalent: ""))

        for station in stationsStore.favorites() {
            menu.addItem(createStationMenuItem(station))
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func buildMarginFavoritesMenu(menu: NSMenu) {
        func build(root: Group, menu: NSMenu, prefix: String = "") {
            for node in root.nodes {
                if let station = node as? Station {
                    if station.isFavorite {
                        menu.addItem(createStationMenuItem(station, prefix: prefix))
                    }
                    continue
                }

                if let group = node as? Group {
                    let n = menu.numberOfItems

                    build(root: group, menu: menu, prefix: prefix + menuPrefix + "  ")
                    if menu.numberOfItems > n {
                        let groupItem = NSMenuItem(title: prefix + group.name, action: nil, keyEquivalent: "")
                        menu.insertItem(groupItem, at: n)
                    }
                }
            }
        }

        menu.addItem(NSMenuItem(title: "Favorite stations".tr, action: nil, keyEquivalent: ""))
        build(root: stationsStore.root, menu: menu, prefix: menuPrefix)
    }

    /* ****************************************
     *
     * ****************************************/
    func buildSubmenuFavoritesMenu(menu: NSMenu) {
        func build(root: Group, menu: NSMenu, prefix: String = "") {
            for node in root.nodes {
                if let station = node as? Station {
                    if station.isFavorite {
                        menu.addItem(createStationMenuItem(station, prefix: prefix))
                    }
                    continue
                }

                if let group = node as? Group {
                    let subMenu = NSMenu()
                    build(root: group, menu: subMenu)
                    if subMenu.numberOfItems > 0 {
                        let subMenuItem = NSMenuItem(title: prefix + group.name, action: nil, keyEquivalent: "")
                        subMenuItem.submenu = subMenu
                        menu.addItem(subMenuItem)
                    }
                }
            }
        }

        menu.addItem(NSMenuItem(title: "Favorite stations".tr, action: nil, keyEquivalent: ""))
        build(root: stationsStore.root, menu: menu, prefix: menuPrefix)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func playerStatusChanged() {
        icon.playerStatus = player.status
        updateTooltip()
    }

    @objc func playerVolumeChanged() {
        icon.muted = player.isMuted
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func updateTooltip() {
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
                    player.title +
                    "\n⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯\n" +
                    player.stationName
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func stationClicked(_ sender: NSMenuItem) {
        guard let station = stationsStore.station(byId: sender.tag) else { return }

        if player.station?.id == station.id && player.isPlaying {
            player.stop()
            return
        }

        player.station = station
        settings.lastStationUrl = station.url
        player.play()
    }
}
