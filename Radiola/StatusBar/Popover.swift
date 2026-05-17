//
//  Popover.swift
//  Radiola
//
//  Created by Alex Sokolov on 09.05.2026.
//

import Cocoa
import Foundation

// MARK: - Popover

class Popover: NSPopover {
    /* ****************************************
     *
     * ****************************************/
    override init() {
        super.init()
        behavior = .transient
        animates = true

        let view = PopoverView()
        let viewController = NSViewController()
        viewController.view = view
        contentViewController = viewController
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - PopoverView

class PopoverView: NSView {
    private let stack = NSStackView()

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(frame: .zero)

        stack.orientation = .vertical
        stack.spacing = 0
        stack.alignment = .width
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.edgeInsets = NSEdgeInsets(top: 0, left: 16, bottom: 6, right: 16)
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reValidate),
                                               name: Notification.Name.PlayerMetadataChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reValidate),
                                               name: Notification.Name.PlayerStatusChanged,
                                               object: nil)

        createMenu()

        reValidate()
        layoutSubtreeIfNeeded()
        let size = stack.fittingSize
        frame = NSRect(origin: .zero, size: size)
    }

    /* ****************************************
     *
     * ****************************************/
    private func createMenu() {
        addPlayerView()
        addVolumeView()

        addSeparator()
        switch settings.favoritesMenuType {
            case .flat: buildFlatFavoritesMenu()
            case .margin: buildMarginFavoritesMenu()
            case .submenu: buildSubmenuFavoritesMenu()
        }

        // =============
        if settings.showCopyToClipboardInMenu {
            addSeparator()

            addItem(
                title: NSLocalizedString("Copy song title and artist", comment: "Status bar menu item"),
                action: #selector(AppDelegate.copySongToClipboard(_:)),
                keyEquivalent: "c")
        }

        addSeparator()

        addItem(
            title: NSLocalizedString("Open Radiola…", comment: "Status bar menu item"),
            action: #selector(AppDelegate.showStationView(_:)),
            keyEquivalent: "r")

        addItem(
            title: NSLocalizedString("History…", comment: "Status bar menu item"),
            action: #selector(AppDelegate.showHistory(_:)),
            keyEquivalent: "y")

        addItem(
            title: NSLocalizedString("Settings…", comment: "Status bar menu item"),
            action: #selector(AppDelegate.showPreferences(_:)),
            keyEquivalent: ",")

        addItem(
            title: NSLocalizedString("Quit", comment: "Status bar menu item"),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q")
    }

    /* ****************************************
     *
     * ****************************************/
    private func addPlayerView() {
        let view = PlayItemView()

        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        view.widthAnchor.constraint(equalToConstant: 500).isActive = true
        view.topMargin = 5
        addView(view)
    }

    /* ****************************************
     *
     * ****************************************/
    private func addVolumeView() {
        let showVolume = settings.showVolumeInMenu
        let showMute = settings.showMuteInMenu

        if !showVolume && !showMute {
            return
        }

        if !showVolume && showMute {
            let item = addItem(
                title: player.isMuted ?
                    NSLocalizedString("Unmute", comment: "Status bar menu Item") :
                    NSLocalizedString("Mute", comment: "Status bar menu Item"),
                action: #selector(Player.toggleMute),
                keyEquivalent: "m")
            item.target = player
            return
        }

        let view = NSView()
        let volumeView = VolumeView(showMuteButton: showMute)
        let airPlayButton = AirPlayButton()

        volumeView.translatesAutoresizingMaskIntoConstraints = true

        volumeView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        airPlayButton.setContentHuggingPriority(.required, for: .horizontal)

        let hStack = NSStackView()
        hStack.spacing = 20
        hStack.alignment = .centerY
        hStack.distribution = .fill
        hStack.edgeInsets = NSEdgeInsets(top: 4, left: 0, bottom: 8, right: 0)
        hStack.addArrangedSubview(volumeView)
        hStack.addArrangedSubview(airPlayButton)

        view.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 3),
            hStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6),

            hStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        airPlayButton.translatesAutoresizingMaskIntoConstraints = false
        airPlayButton.heightAnchor.constraint(equalToConstant: 16).isActive = true
        airPlayButton.widthAnchor.constraint(equalToConstant: 16).isActive = true

        addView(view)
    }

    /* ****************************************
     *
     * ****************************************/
    @discardableResult
    private func addView(_ view: NSView) -> NSView {
        stack.addArrangedSubview(view)
        return view
    }

    /* ****************************************
     *
     * ****************************************/
    @discardableResult
    private func addItem(_ item: PopoverItem) -> PopoverItem {
        addView(item)
        return item
    }

    /* ****************************************
     *
     * ****************************************/
    @discardableResult
    private func insertItem(_ item: PopoverItem, at index: Int) -> PopoverItem {
        stack.insertArrangedSubview(item, at: index)
        return item
    }

    /* ****************************************
     *
     * ****************************************/
    @discardableResult
    private func addSeparator() -> Separator {
        let res = Separator()
        res.heightAnchor.constraint(equalToConstant: 10).isActive = true
        addView(res)
        return res
    }

    /* ****************************************
     *
     * ****************************************/
    private func stationKeyEquivalent(_ num: Int) -> String {
        return num < 10 ? "\(num)" : ""
    }

    /* ****************************************
     *
     * ****************************************/
    private func buildFlatFavoritesMenu() {
        addItem(title: NSLocalizedString("Favorite stations", comment: "Status bar menu item"), action: nil, keyEquivalent: "")

        for (i, station) in AppState.shared.favoritesStations().enumerated() {
            addItem(createStationItem(station, keyEquivalent: stationKeyEquivalent(i + 1)))
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func buildMarginFavoritesMenu() {
        var num = 0
        let menuPrefix = "  "

        func build(items: [StationItem], prefix: String = "") {
            for item in items {
                if let station = item as? Station {
                    if station.isFavorite {
                        num += 1
                        addItem(createStationItem(station, prefix: prefix, keyEquivalent: stationKeyEquivalent(num)))
                    }
                }

                if let group = item as? StationGroup {
                    let n = stack.arrangedSubviews.count

                    build(items: group.items, prefix: prefix + menuPrefix + "  ")
                    if stack.arrangedSubviews.count > n {
                        let groupItem = PopoverItem(title: prefix + group.title, action: nil, keyEquivalent: "")
                        insertItem(groupItem, at: n)
                    }
                }
            }
        }

        addItem(title: NSLocalizedString("Favorite stations", comment: "Status bar menu item"), action: nil, keyEquivalent: "")
        for list in AppState.shared.localStations {
            build(items: list.items, prefix: menuPrefix)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func buildSubmenuFavoritesMenu() {
        /* ****************************************
         *
         * ****************************************/
        func createStationMenuItem(_ station: Station, keyEquivalent: String = "") -> NSMenuItem {
            let res = NSMenuItem(
                title: station.title,
                action: #selector(stationClicked(_:)),
                keyEquivalent: keyEquivalent)

            res.target = self
            res.representedObject = station

            return res
        }

        func build(items: [StationItem], menu: NSMenu) {
            var num = 0
            for item in items {
                if let station = item as? Station {
                    if station.isFavorite {
                        num += 1
                        menu.addItem(createStationMenuItem(station, keyEquivalent: stationKeyEquivalent(num)))
                    }
                }

                if let group = item as? StationGroup {
                    let subMenu = NSMenu()
                    build(items: group.items, menu: subMenu)
                    if subMenu.numberOfItems > 0 {
                        let subMenuItem = NSMenuItem(title: group.title, action: nil, keyEquivalent: "")
                        subMenuItem.submenu = subMenu
                        menu.addItem(subMenuItem)
                    }
                }
            }
        }

        var num = 0
        addItem(title: NSLocalizedString("Favorite stations", comment: "Status bar menu item"), action: nil, keyEquivalent: "")
        for list in AppState.shared.localStations {
            for item in list.items {
                if let station = item as? Station {
                    if station.isFavorite {
                        num += 1
                        addItem(createStationItem(station, prefix: "", keyEquivalent: stationKeyEquivalent(num)))
                    }
                }

                if let group = item as? StationGroup {
                    let menu = NSMenu()

                    build(items: group.items, menu: menu)
                    if menu.numberOfItems > 0 {
                        let item = addItem(title: group.title)
                        item.menu = menu
                    }
                }
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func reValidate() {
        func walk(_ view: NSView) {
            for subview in view.subviews {
                if let item = subview as? PopoverItem {
                    item.validate()
                }
            }
        }

        walk(stack)
    }

    /* ****************************************
     *
     * ****************************************/
    @discardableResult
    private func addItem(title: String, action selector: Selector? = nil, keyEquivalent: String = "") -> PopoverItem {
        let res = PopoverItem(title: title, keyEquivalent: keyEquivalent)
        res.action = selector
        addView(res)
        return res
    }

    /* ****************************************
     *
     * ****************************************/
    private func createStationItem(_ station: Station, prefix: String = "", keyEquivalent: String = "") -> PopoverItem {
        let res = PopoverItem(
            title: prefix + station.title,
            action: #selector(stationClicked(_:)),
            keyEquivalent: keyEquivalent)

        res.target = self
        res.representedObject = station

        return res
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func stationClicked(_ sender: NSObject) {
        var station: Station?
        station = (sender as? PopoverItem)?.representedObject as? Station
        if station == nil {
            station = (sender as? NSMenuItem)?.representedObject as? Station
        }

        if let station {
            player.switchStation(station: station)
        }
    }
}
