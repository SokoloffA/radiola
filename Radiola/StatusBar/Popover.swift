//
//  Popover.swift
//  Radiola
//
//  Created by Alex Sokolov on 09.05.2026.
//

import Cocoa
import Foundation

// MARK: - Popover

class Popover: NSPanel, NSWindowDelegate {
    private static var instance: Popover?
    private var mouseLocalMonitor: Any?
    private var mouseGlobalMonitor: Any?

    /* ****************************************
     *
     * ****************************************/
    static func show(relativeTo positioningRect: NSRect) {
        if instance == nil {
            instance = Popover()
        }

        guard
            let instance = instance,
            let contentView = instance.contentView as? PopoverView,
            let screen = NSScreen.screens.first(where: { NSMouseInRect(NSPoint(x: positioningRect.midX, y: positioningRect.midY), $0.frame, false) }) ?? NSScreen.main
        else {
            return
        }

        var size = instance.frame.size
        size.height = min(size.height, screen.visibleFrame.height - 4)

        let yCoord = positioningRect.origin.y - size.height - 4
        var xCoord = positioningRect.origin.x + (positioningRect.width / 2) - (size.width / 2)
        if xCoord + size.width > screen.visibleFrame.maxX {
            xCoord = screen.visibleFrame.maxX - size.width
        }

        let rect = NSRect(
            x: xCoord,
            y: yCoord,
            width: size.width,
            height: size.height
        )

        instance.setFrame(rect, display: true)
        contentView.scrollToTop()
        instance.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /* ****************************************
     *
     * ****************************************/
    static func close() {
        instance?.close()
    }

    /* ****************************************
     *
     * ****************************************/
    static func toggle(relativeTo positioningRect: NSRect) {
        if instance == nil {
            Popover.show(relativeTo: positioningRect)
        } else {
            Popover.close()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private init() {
        let contentView = PopoverView()
        contentView.layoutSubtreeIfNeeded()
        let size = contentView.preferredSize()

        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )

        delegate = self

        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        isOpaque = false
        backgroundColor = .clear
        hasShadow = true

        self.contentView = contentView
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = 12
        contentView.layer?.masksToBounds = true
        self.contentView = contentView

        // minSize = NSSize(width: 250, height: 300)
        // maxSize = NSSize(width: 800, height: 1280)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(popupDidResignKey),
            name: NSWindow.didResignKeyNotification,
            object: self
        )

        mouseLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp, .otherMouseUp]) { [weak self] event in
            if event.window != self { self?.close() }
            return event
        }

        mouseGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp, .otherMouseUp]) { [weak self] event in
            if event.window != self { self?.close() }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /* ****************************************
     *
     * ****************************************/
    deinit {
        if let monitor = mouseLocalMonitor {
            NSEvent.removeMonitor(monitor)
        }

        if let monitor = mouseGlobalMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    override func close() {
        Popover.instance = nil
        super.close()
    }

    /* ****************************************
         *
     * ****************************************/
    @objc private func popupDidResignKey(_ notification: Notification) {
        close()
    }

    /* ****************************************
     *
     * ****************************************/
    override var canBecomeKey: Bool {
        return true
    }

    /* ****************************************
     *
     * ****************************************/
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        let delta = frameSize.width - frame.width
        let newOriginX = frame.origin.x - delta / 2

        DispatchQueue.main.async {
            var newFrame = self.frame
            newFrame.origin.x = newOriginX
            newFrame.size = frameSize
            super.setFrame(newFrame, display: true)
        }

        return frameSize
    }
}

// MARK: - PopoverView

class PopoverView: NSView {
    fileprivate let stack = VerticalLayout()
    private let scrollView = NSScrollView()
    private let stationsStack = VerticalLayout()
    private let topArrow = Arrow(systemSymbolName: "chevron.compact.up", accessibilityDescription: "upbutton")
    private let bottomArrow = Arrow(systemSymbolName: "chevron.compact.down", accessibilityDescription: "down button")

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
        wantsLayer = true

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.edgeInsets = NSEdgeInsets(top: 0, left: 16, bottom: 6, right: 16)
        addSubview(stack)

        stationsStack.translatesAutoresizingMaskIntoConstraints = false
        stationsStack.edgeInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.documentView = stationsStack

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),

            stationsStack.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            stationsStack.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
        ])

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reValidate),
                                               name: Notification.Name.PlayerMetadataChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reValidate),
                                               name: Notification.Name.PlayerStatusChanged,
                                               object: nil)

        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(scrollViewDidScroll),
                                               name: NSView.boundsDidChangeNotification,
                                               object: scrollView.contentView)

        createMenu()

        addSubview(topArrow)
        addSubview(bottomArrow)
        NSLayoutConstraint.activate([
            topArrow.heightAnchor.constraint(equalToConstant: 10),
            topArrow.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: -2),
            topArrow.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            topArrow.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),

            bottomArrow.heightAnchor.constraint(equalToConstant: 10),
            bottomArrow.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 2),
            bottomArrow.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            bottomArrow.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
        ])

        reValidate()
        layoutSubtreeIfNeeded()
        let size = stack.fittingSize
        frame = NSRect(origin: .zero, size: size)
    }

    /* ****************************************
     *
     * ****************************************/
    override func updateLayer() {
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        topArrow.layer?.backgroundColor = layer?.backgroundColor
        bottomArrow.layer?.backgroundColor = layer?.backgroundColor
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func scrollViewDidScroll(_ notification: Notification) {
        let contentView = scrollView.contentView
        let totalHeight = stationsStack.fittingSize.height
        let visibleHeight = contentView.bounds.height
        let currentScrollY = contentView.bounds.origin.y

        if totalHeight <= visibleHeight + 2 {
            topArrow.isHidden = true
            bottomArrow.isHidden = true
            return
        }

        let maxScrollY = totalHeight - visibleHeight
        topArrow.isHidden = currentScrollY >= maxScrollY - 1

        bottomArrow.isHidden = currentScrollY <= 1
    }

    /* ****************************************
     *
     * ****************************************/
    fileprivate func scrollToTop() {
        guard let documentView = scrollView.documentView else { return }
        let topPoint = NSPoint(x: 0, y: documentView.frame.height - scrollView.contentView.bounds.height)
        scrollView.contentView.scroll(to: topPoint)
    }

    /* ****************************************
     *
     * ****************************************/
    fileprivate func preferredSize() -> CGSize {
        return CGSize(
            width: stack.frame.width,
            height: frame.height - scrollView.frame.height + stationsStack.frame.height)
    }

    /* ****************************************
     *
     * ****************************************/
    private func createMenu() {
        addPlayerView()
        addVolumeView()

        stack.addSeparator()
        stack.addItem(title: NSLocalizedString("Favorite stations", comment: "Status bar menu item"), action: nil, keyEquivalent: "")
        stack.addView(scrollView)

        switch settings.favoritesMenuType {
            case .flat: buildFlatFavoritesMenu()
            case .margin: buildMarginFavoritesMenu()
            case .submenu: buildSubmenuFavoritesMenu()
        }

        // =============
        if settings.showCopyToClipboardInMenu {
            stack.addSeparator()

            stack.addItem(
                title: NSLocalizedString("Copy song title and artist", comment: "Status bar menu item"),
                action: #selector(AppDelegate.copySongToClipboard(_:)),
                keyEquivalent: "c")
        }

        stack.addSeparator()

        stack.addItem(
            title: NSLocalizedString("Open Radiola…", comment: "Status bar menu item"),
            action: #selector(AppDelegate.showStationView(_:)),
            keyEquivalent: "r")

        stack.addItem(
            title: NSLocalizedString("History…", comment: "Status bar menu item"),
            action: #selector(AppDelegate.showHistory(_:)),
            keyEquivalent: "y")

        stack.addItem(
            title: NSLocalizedString("Settings…", comment: "Status bar menu item"),
            action: #selector(AppDelegate.showPreferences(_:)),
            keyEquivalent: ",")

        stack.addItem(
            title: NSLocalizedString("Quit", comment: "Status bar menu item"),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q")
    }

    /* ****************************************
     *
     * ****************************************/
    private func addPlayerView() {
        let view = PlayMenuItem()

        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        view.topMargin = 5

        view.playButton.keyEquivalent = "p"
        view.playButton.keyEquivalentModifierMask = .command

        stack.addView(view)
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
            let item = stack.addItem(
                title: player.isMuted ?
                    NSLocalizedString("Unmute", comment: "Status bar menu Item") :
                    NSLocalizedString("Mute", comment: "Status bar menu Item"),
                action: #selector(Player.toggleMute),
                keyEquivalent: "m")
            item.target = player
            return
        }

        let view = NSView()
        let volumeView = VolumeView(showMuteButton: true)
        let airPlayButton = AirPlayButton()

        volumeView.muteButton?.keyEquivalent = "m"
        volumeView.muteButton?.keyEquivalentModifierMask = .command

        volumeView.downButton.keyEquivalent = String(UnicodeScalar(NSDownArrowFunctionKey)!)
        volumeView.downButton.keyEquivalentModifierMask = .command

        volumeView.upButton.keyEquivalent = String(UnicodeScalar(NSUpArrowFunctionKey)!)
        volumeView.upButton.keyEquivalentModifierMask = .command

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

        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 30).isActive = true

        stack.addView(view)
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
        for (i, station) in AppState.shared.favoritesStations().enumerated() {
            stationsStack.addItem(createStationItem(station, keyEquivalent: stationKeyEquivalent(i + 1)))
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
                        stationsStack.addItem(createStationItem(station, prefix: prefix, keyEquivalent: stationKeyEquivalent(num)))
                    }
                }

                if let group = item as? StationGroup {
                    let n = stationsStack.arrangedSubviews.count

                    build(items: group.items, prefix: prefix + menuPrefix + "  ")
                    if stationsStack.arrangedSubviews.count > n {
                        let groupItem = PopoverItem(title: prefix + group.title, action: nil, keyEquivalent: "")
                        stationsStack.insertItem(groupItem, at: n)
                    }
                }
            }
        }

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
        for list in AppState.shared.localStations {
            for item in list.items {
                if let station = item as? Station {
                    if station.isFavorite {
                        num += 1
                        stationsStack.addItem(createStationItem(station, prefix: "", keyEquivalent: stationKeyEquivalent(num)))
                    }
                }

                if let group = item as? StationGroup {
                    let menu = NSMenu()

                    build(items: group.items, menu: menu)
                    if menu.numberOfItems > 0 {
                        let item = stationsStack.addItem(title: group.title)
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
                walk(subview)
            }
        }

        walk(self)
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
            window?.close()
        }
    }
}

// MARK: - VerticalLayout

fileprivate extension VerticalLayout {
    /* ****************************************
     *
     * ****************************************/
    @discardableResult
    func addView(_ view: NSView) -> NSView {
        addArrangedSubview(view)
        return view
    }

    /* ****************************************
     *
     * ****************************************/
    @discardableResult
    func addItem(_ item: PopoverItem) -> PopoverItem {
        addView(item)
        return item
    }

    /* ****************************************
     *
     * ****************************************/
    @discardableResult
    func addItem(title: String, action selector: Selector? = nil, keyEquivalent: String = "") -> PopoverItem {
        let res = PopoverItem(title: title, keyEquivalent: keyEquivalent)
        res.action = selector
        addView(res)
        return res
    }

    /* ****************************************
     *
     * ****************************************/
    @discardableResult
    func insertItem(_ item: PopoverItem, at index: Int) -> PopoverItem {
        insertArrangedSubview(item, at: index)
        return item
    }

    /* ****************************************
     *
     * ****************************************/
    @discardableResult
    func addSeparator() -> Separator {
        let res = Separator()
        res.heightAnchor.constraint(equalToConstant: 10).isActive = true
        addView(res)
        return res
    }
}

// MARK: - Arrow

fileprivate class Arrow: NSImageView {
    /* ****************************************
     *
     * ****************************************/
    init(image: NSImage? = nil) {
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        self.image = image
        imageScaling = .scaleProportionallyUpOrDown
        contentTintColor = .secondaryLabelColor
        wantsLayer = true
        isHidden = true
    }

    /* ****************************************
     *
     * ****************************************/
    convenience init(systemSymbolName: String, accessibilityDescription: String) {
        self.init(image: NSImage(systemSymbolName: NSImage.Name(systemSymbolName), accessibilityDescription: accessibilityDescription))
    }

    /* ****************************************
     *
     * ****************************************/
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
