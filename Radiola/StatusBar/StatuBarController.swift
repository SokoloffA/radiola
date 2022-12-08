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

    /* ****************************************
     *
     * ****************************************/
    private let startConnectionPauseIcon = 0
    private let connectionIcon = AnimatedIcon(
        size: 16, frames: [
            "connect-2",
            "connect-3",
            "connect-4",
            "connect-5",
            "connect-6",
            "connect-5",
            "connect-4",
            "connect-3",
        ]
    )

    /* ****************************************
     *
     * ****************************************/
    override init() {
        super.init()
        connectionIcon.statusItem = menuItem
        connectionIcon.framesPerSecond = 8

        setIcon(item: menuItem, icon: "MenuButtonImage", size: 16)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerStatusChanged),
                                               name: Notification.Name.PlayerStatusChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateTooltip),
                                               name: Notification.Name.PlayerMetadataChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(rebuildMenu),
                                               name: Notification.Name.StationsChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(rebuildMenu),
                                               name: Notification.Name.SettingsChanged,
                                               object: nil)

        playerStatusChanged()
        rebuildMenu()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func rebuildMenu() {
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
            title: "Show History",
            action: #selector(AppDelegate.showHistory(_:)),
            keyEquivalent: "y"))

        menu.addItem(NSMenuItem(
            title: "Quit".tr,
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"))

        menuItem.menu = menu
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
        switch player.status {
        case Player.Status.paused:
            connectionIcon.stop()
            setIcon(item: menuItem, icon: "MenuButtonImage", size: 16)

        case Player.Status.connecting:
            connectionIcon.start(startFrame: 0)

        case Player.Status.playing:
            connectionIcon.stop()
            setIcon(item: menuItem, icon: "MenuButtonPlay", size: 16)
        }

        updateTooltip()
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
    private func setIcon(item: NSStatusItem, icon: String, size: Int = 12) {
        let img = NSImage(named: NSImage.Name(icon))
        img?.size = NSSize(width: size, height: size)
        img?.isTemplate = true
        item.button?.image = img
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
