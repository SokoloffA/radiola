//
//  StatuBarController.swift
//  Radiola
//
//  Created by Alex Sokolov on 27.11.2022.
//

import Cocoa
import SwiftUI

fileprivate let playItemWidth = 350.0
fileprivate let playItemHeght = 50.0
fileprivate let volumeItemHeght = 40.0

// MARK: - PlayItem

fileprivate class PlayItem: NSMenuItem {
    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(title: "", action: nil, keyEquivalent: "")

        view = NSHostingView(rootView: RootView(menuItem: self))
        view?.frame.size = NSSize(width: playItemWidth, height: playItemHeght)
        isEnabled = true
    }

    /* ****************************************
     *
     * ****************************************/
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /* ****************************************
     *
     * ****************************************/
    fileprivate struct RootView: View {
        @StateObject var player = Player.shared
        weak var menuItem: NSMenuItem?

        var body: some View {
            HStack {
                Image(systemName: icon())
                    .resizable()
                    .frame(width: 12, height: 16)
                    .padding(EdgeInsets(top: 0, leading: 23, bottom: 0, trailing: 13))

                VStack {
                    Text(player.songTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.headline)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
                        .truncationMode(.tail)
                        .lineLimit(1)
                        .frame(minHeight: 16)

                    Text(player.station?.title ?? "")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.subheadline)
                        .truncationMode(.tail)
                        .lineLimit(1)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: clicked)
        } // body

        /* ****************************************
         *
         * ****************************************/
        private func icon() -> String {
            switch player.status {
                case Player.Status.paused: return "play.fill"
                case Player.Status.connecting: return "pause.fill"
                case Player.Status.playing: return "pause.fill"
            }
        }

        /* ****************************************
         *
         * ****************************************/
        private func clicked() {
            player.toggle()
            menuItem?.menu?.cancelTracking()
        }
    } // RootView
}

// MARK: - VolumeItem

fileprivate class VolumeItem: NSMenuItem {
    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(title: "", action: nil, keyEquivalent: "")

        view = NSHostingView(rootView: RootView(menuItem: self))
        view?.frame.size = NSSize(width: playItemWidth, height: volumeItemHeght)
        isEnabled = true
    }

    /* ****************************************
     *
     * ****************************************/
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /* ****************************************
     *
     * ****************************************/
    struct RootView: View {
        @StateObject var player = Player.shared
        weak var menuItem: NSMenuItem?

        var body: some View {
            Text("VOLUME")
        }
    } // RootView
}

// MARK: - StatusBarController

class StatusBarController: NSObject {
    private let appState = AppState.shared
    let menuItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menuPrefix = "  "
    private let icon = StatusBarIcon(size: 16)
    private let player = Player.shared

    /* ****************************************
     *
     * ****************************************/
    override init() {
        super.init()
        icon.statusItem = menuItem
        icon.framesPerSecond = 8
        icon.playerStatus = Player.shared.status
        icon.muted = player.isMuted

//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(playerStatusChanged),
//                                               name: Notification.Name.PlayerStatusChanged,
//                                               object: nil)
//
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(updateTooltip),
//                                               name: Notification.Name.PlayerMetadataChanged,
//                                               object: nil)
//
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(playerVolumeChanged),
//                                               name: Notification.Name.PlayerVolumeChanged,
//                                               object: nil)
//
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(updateTooltip),
//                                               name: Notification.Name.SettingsChanged,
//                                               object: nil)

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

        return config.mouseAction(forButton: btn)
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
                MainWindow.show()
                return nil

            case .showHistory:
                //    _ = HistoryWindow.show()
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

        if config.mouseWheelAction != MouseWheelAction.nothing {
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

        menu.addItem(PlayItem())
        menu.addItem(NSMenuItem.separator())

        if config.showVolumeInMenu {
            menu.addItem(VolumeItem())
        }

        if config.showMuteInMenu {
            let item = NSMenuItem(
                title: player.isMuted ? "Unmute" : "Mute",
                action: #selector(Player.toggleMute),
                keyEquivalent: "m")
            item.target = player
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        switch config.favoritesMenuType {
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
        func build(items: [LocalStationList.Item], menu: NSMenu, prefix: String = "") {
            for item in items {
                switch item {
                    case let .station(station: station):
                        if station.isFavorite {
                            menu.addItem(createStationMenuItem(station, prefix: prefix))
                        }

                    case let .group(group: group):
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
        func build(items: [LocalStationList.Item], menu: NSMenu, prefix: String = "") {
            for item in items {
                switch item {
                    case let .station(station: station):
                        if station.isFavorite {
                            menu.addItem(createStationMenuItem(station, prefix: prefix))
                        }

                    case let .group(group: group):
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

    @objc func playerVolumeChanged() {
        icon.muted = player.isMuted
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func updateTooltip() {
        if config.showTooltip == false {
            menuItem.button?.toolTip = ""
            return
        }

        switch player.status {
            case Player.Status.paused:
                menuItem.button?.toolTip = player.station?.title

            case Player.Status.connecting:
                menuItem.button?.toolTip =
                    (player.station?.title ?? "") +
                    "\n⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯\n" +
                    "Connecting...".tr(withComment: "Tooltip text")

            case Player.Status.playing:
                menuItem.button?.toolTip =
                    player.songTitle +
                    "\n⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯\n" +
                    (player.station?.title ?? "")
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func stationClicked(_ sender: NSMenuItem) {
//        guard let station = stationsStore.station(byId: sender.tag) else { return }
//
//        if player.station?.id == station.id && player.isPlaying {
//            player.stop()
//            return
//        }
//
//        player.station = station
//        player.play()
    }
}
