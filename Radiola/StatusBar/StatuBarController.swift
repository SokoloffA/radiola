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
    private let icon = StatusBarIcon(size: 16)
    private let padding: CGFloat = 2

    private var middleMouseMonitor: Any?
    private var scrollWheelMonitor: Any?

    private var popoverAnchor: NSView?

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
                                               selector: #selector(updateTexts),
                                               name: Notification.Name.PlayerMetadataChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerVolumeChanged),
                                               name: Notification.Name.PlayerVolumeChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateTexts),
                                               name: Notification.Name.SettingsChanged,
                                               object: nil)

        menuItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp, .otherMouseUp])
        menuItem.button?.target = self
        menuItem.button?.action = #selector(leftRightMouseAction)
        menuItem.button?.imagePosition = .imageRight
        middleMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.otherMouseDown, .otherMouseUp], handler: middleMouseDown)
        scrollWheelMonitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel], handler: scrollWheel)

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
                showPopover()
                break

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
    func showPopover() {
        guard let button = menuItem.button else { return }
        if popoverAnchor == nil {
            let size = button.bounds.height
            let anchor = NSView(frame: NSRect(x: button.bounds.maxX - size, y: button.bounds.minY, width: size, height: size))

            button.addSubview(anchor)
            anchor.autoresizingMask = [.minXMargin]

            popoverAnchor = anchor
        }
        let popover = Popover()
        popover.show(relativeTo: popoverAnchor!.bounds, of: popoverAnchor!, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
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
    @objc func playerStatusChanged() {
        icon.playerStatus = player.status
        updateTexts()
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
    @objc func updateTexts() {
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
        if settings.showSongInStatusBar {
            switch player.status {
                case Player.Status.paused:
                    str = ""

                case Player.Status.connecting:
                    str = ""

                case Player.Status.playing:
                    str = player.songTitle
            }
        }

        setItemText(str)
    }

    /* ****************************************
     *
     * ****************************************/
    private func setItemText(_ str: String) {
        guard let button = menuItem.button else { return }

        if str.isEmpty {
            button.attributedTitle = NSAttributedString()
            menuItem.length = CGFloat(icon.size) + padding * 2
            return
        }

        let label = NSMutableAttributedString()
        label.append(NSAttributedString(string: str.truncateMiddle(maxLength: 50)))
        label.append(NSAttributedString(
            string: " ",
            attributes: [.kern: 16] // the distance between the image and the text
        ))

        menuItem.length = NSStatusItem.variableLength
        button.attributedTitle = label
    }
}
