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
    private let menuItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let icon = StatusBarIcon(size: 16)
    private let padding: CGFloat = 2

    private var popover: Popover?
    private var mouseClickLocalMonitor: Any?
    private var mouseClickGlobalMonitor: Any?
    private var mouseScrollLocalMonitor: Any?
    private var mouseScrollGlobalMonitor: Any?

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
                                               selector: #selector(refresh),
                                               name: Notification.Name.PlayerMetadataChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerVolumeChanged),
                                               name: Notification.Name.PlayerVolumeChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refresh),
                                               name: Notification.Name.SettingsChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refresh),
                                               name: NSApplication.didChangeScreenParametersNotification,
                                               object: nil
        )

        menuItem.button?.imagePosition = .imageTrailing

        let eventTypeMask: NSEvent.EventTypeMask = [
            .leftMouseDown, .rightMouseDown, .otherMouseDown,
            .leftMouseUp, .rightMouseUp, .otherMouseUp]

        mouseClickGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventTypeMask) { [weak self] event in self?.mouseClickEvent(event) }
        mouseClickLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: eventTypeMask) { [weak self] event in self?.mouseClickEvent(event); return event }
        mouseScrollGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.scrollWheel]) { [weak self] event in self?.mouseScrollEvent(event) }
        mouseScrollLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { [weak self] event in self?.mouseScrollEvent(event); return event }

        playerStatusChanged()
    }

    /* ****************************************
     *
     * ****************************************/
    deinit {
        if let monitor = mouseClickGlobalMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = mouseClickLocalMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = mouseScrollGlobalMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = mouseScrollLocalMonitor { NSEvent.removeMonitor(monitor) }
    }

    /* ****************************************
     *
     * ****************************************/
    private func mouseOverButton(_ event: NSEvent) -> Bool {
        guard
            let btnWindow = menuItem.button?.window
        else {
            return false
        }

        if let wnd = event.window {
            return wnd == btnWindow
        } else {
            return btnWindow.frame.contains(event.locationInWindow)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func mouseClickEvent(_ event: NSEvent) {
        if event.eventNumber == 0 {
            return
        }

        if mouseOverButton(event) {
            switch event.type {
                case .leftMouseDown, .rightMouseDown, .otherMouseDown:
                    mouseDownEvent(event)

                case .leftMouseUp, .rightMouseUp, .otherMouseUp:
                    mouseUpEvent(event)

                case .scrollWheel: mouseScrollEvent(event)
                default: break
            }
            return
        }

        if let popover = popover {
            var pos = event.locationInWindow
            if let window = event.window {
                pos = window.convertPoint(toScreen: pos)
            }

            if pos.y > popover.frame.maxY {
                closePopover()
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func mouseDownEvent(_ event: NSEvent) {
        menuItem.button?.highlight(true)

        var action: MouseButtonAction?
        switch event.type {
            case .leftMouseDown:
                action = settings.mouseAction(forButton: .left)

            case .rightMouseDown:
                action = settings.mouseAction(forButton: .right)

            case .otherMouseDown:
                action = settings.mouseAction(forButton: .middle)

            default:
                break
        }

        if action != .showMenu {
            closePopover()
        }

        switch action {
            case .none:
                return

            case .showMenu:
                togglePopover()

            case .playPause:
                player.toggle()

            case .showMainWindow:
                StationsWindow.show()

            case .showHistory:
                StationsWindow.showHistory()

            case .mute:
                player.isMuted = !player.isMuted

            case .markAsFavorite:
                player.isFavoriteSong = true
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func mouseUpEvent(_ event: NSEvent) {
        menuItem.button?.highlight(false)
    }

    /* ****************************************
     *
     * ****************************************/
    private func mouseScrollEvent(_ event: NSEvent) {
        if mouseOverButton(event) {
            switch (settings.mouseWheelAction, event.isDirectionInvertedFromDevice) {
                case (.nothing, _):
                    return

                case (.volume, true):
                    player.volume += Player.mouseWheelToVolume(delta: event.scrollingDeltaY)

                case (.volume, false):
                    player.volume -= Player.mouseWheelToVolume(delta: event.scrollingDeltaY)
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func showPopover() {
        guard
            let button = menuItem.button,
            let window = button.window,
            let cellRect = button.cell?.imageRect(forBounds: button.bounds)
        else {
            return
        }

        let rectInScreen = window.convertToScreen(cellRect)

        guard
            let screen = NSScreen.screens.first(where: { NSMouseInRect(NSPoint(x: rectInScreen.midX, y: rectInScreen.midY), $0.frame, false) }) ?? NSScreen.main
        else {
            return
        }

        if popover == nil {
            popover = Popover()
            popover?.onClose = { [weak self] in self?.popover = nil }
        }

        if let popover = popover {
            var size = popover.frame.size
            size.height = min(size.height, screen.visibleFrame.height - 4)

            let yCoord = rectInScreen.origin.y - size.height - 4
            var xCoord = rectInScreen.origin.x + (rectInScreen.width / 2) - (size.width / 2)
            if xCoord + size.width > screen.visibleFrame.maxX {
                xCoord = screen.visibleFrame.maxX - size.width
            }

            let rect = NSRect(
                x: xCoord,
                y: yCoord,
                width: size.width,
                height: size.height
            )

            popover.setFrame(rect, display: true)
            NSApp.activate(ignoringOtherApps: true)
            popover.makeKeyAndOrderFront(nil)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func closePopover() {
        popover?.close()
    }

    /* ****************************************
     *
     * ****************************************/
    func togglePopover() {
        if popover != nil {
            closePopover()
        } else {
            showPopover()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func playerStatusChanged() {
        icon.playerStatus = player.status
        refresh()
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
    private func isShowSongInStatusBar() -> Bool {
        let cfg = settings.showSongInStatusBar
        if cfg == .never { return false }
        if cfg == .always { return true }

        guard let screen = menuItem.button?.window?.screen else { return false }
        return screen.frame.size.width >= Double(cfg.rawValue)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func refresh() {
        updateTooltip()
        updateItemText()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func updateTooltip() {
        if settings.showTooltip == false {
            menuItem.button?.toolTip = ""
            return
        }

        // "⏸  ⏵ https://www.compart.com/en/unicode/block/U+2300"
        var firstString = ""
        let secondString = player.stationName
        switch player.status {
            case Player.Status.paused:
                firstString = ""

            case Player.Status.connecting:
                firstString = NSLocalizedString("Connecting…", comment: "Tooltip text")

            case Player.Status.playing:
                firstString = player.songTitle
        }

        if firstString.isEmpty {
            menuItem.button?.toolTip = secondString
        } else {
            menuItem.button?.toolTip =
                firstString +
                "\n⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺\n" +
                secondString
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func updateItemText() {
        var str = ""
        if isShowSongInStatusBar() {
            switch player.status {
                case Player.Status.paused:
                    str = ""

                case Player.Status.connecting:
                    str = ""

                case Player.Status.playing:
                    str = player.songTitle
            }
        }

        guard let button = menuItem.button else { return }

        if str.isEmpty {
            button.attributedTitle = NSAttributedString()
            menuItem.length = CGFloat(icon.size) + padding * 2
            return
        }

        str = str.truncatedMiddle(toWidth: CGFloat(settings.songInStatusBarWidth), font: NSFont.menuBarFont(ofSize: 0))

        let label = NSMutableAttributedString()
        label.append(NSAttributedString(string: str))
        label.append(NSAttributedString(
            string: " ",
            attributes: [.kern: 16] // the distance between the image and the text
        ))

        menuItem.length = NSStatusItem.variableLength
        button.attributedTitle = label
    }
}
