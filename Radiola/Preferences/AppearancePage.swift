//
//  AppearancePage.swift
//  Radiola
//
//  Created by Alex Sokolov on 02.07.2023.
//

import Cocoa

class AppearancePage: NSViewController {
    private let favoritesMenuGroupTypeLabel = Label(text: NSLocalizedString("Show groups in favorites:", tableName: "Settings", comment: "Settings label"))
    private let favoritesMenuGroupTypeCbx = NSPopUpButton()
    private let showVolumeCheckBox = Checkbox(title: NSLocalizedString("Show the volume control in the menu", tableName: "Settings", comment: "Settings label"))
    private let showMuteCheckBox = Checkbox(title: NSLocalizedString("Show the mute item in the menu", tableName: "Settings", comment: "Settings label"))
    private let showCopyToClipboardCheckBox = Checkbox(title: NSLocalizedString("Show the \"Copy song title and artist\" item in the menu", tableName: "Settings", comment: "Settings label"))
    private let showToolTipCheckBox = Checkbox(title: NSLocalizedString("Show a tooltip with the radiostation and song", tableName: "Settings", comment: "Settings label"))

    private let notifiactionsLabel = Label(text: NSLocalizedString("Notifications:", tableName: "Settings", comment: "Settings label"))
    private let notificationsWhenPlaybackStarts = Checkbox(title: NSLocalizedString("When playback starts.", tableName: "Settings", comment: "Settings label"))

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(nibName: nil, bundle: nil)

        title = NSLocalizedString("Appearance", tableName: "Settings", comment: "Settings page title")
        view = createView()

        initFavoritesMenuGroupTypeCbx()

        showVolumeCheckBox.state = settings.showVolumeInMenu ? .on : .off
        showVolumeCheckBox.target = self
        showVolumeCheckBox.action = #selector(showVolumeChanged)

        showMuteCheckBox.state = settings.showMuteInMenu ? .on : .off
        showMuteCheckBox.target = self
        showMuteCheckBox.action = #selector(showMuteCheckBoxChanged)

        showToolTipCheckBox.state = settings.showTooltip ? .on : .off
        showToolTipCheckBox.target = self
        showToolTipCheckBox.action = #selector(showTooltipChanged)

        showCopyToClipboardCheckBox.state = settings.showCopyToClipboardInMenu ? .on : .off
        showCopyToClipboardCheckBox.target = self
        showCopyToClipboardCheckBox.action = #selector(showCopyToClipboardChanged)
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
    private func createView() -> NSView {
        let res = NSView()
        res.autoresizingMask = [.maxXMargin, .minYMargin]

        res.addSubview(favoritesMenuGroupTypeLabel)
        res.addSubview(favoritesMenuGroupTypeCbx)
        res.addSubview(showVolumeCheckBox)
        res.addSubview(showMuteCheckBox)
        res.addSubview(showCopyToClipboardCheckBox)
        res.addSubview(showToolTipCheckBox)

        favoritesMenuGroupTypeLabel.alignment = .right
        favoritesMenuGroupTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        favoritesMenuGroupTypeCbx.translatesAutoresizingMaskIntoConstraints = false
        favoritesMenuGroupTypeCbx.topAnchor.constraint(equalTo: res.topAnchor, constant: 20).isActive = true
        favoritesMenuGroupTypeLabel.leadingAnchor.constraint(equalTo: res.leadingAnchor, constant: 16).isActive = true
        favoritesMenuGroupTypeCbx.leadingAnchor.constraint(equalTo: favoritesMenuGroupTypeLabel.trailingAnchor, constant: 20).isActive = true
        favoritesMenuGroupTypeLabel.centerYAnchor.constraint(equalTo: favoritesMenuGroupTypeCbx.centerYAnchor).isActive = true

        showVolumeCheckBox.translatesAutoresizingMaskIntoConstraints = false
        showVolumeCheckBox.topAnchor.constraint(equalTo: favoritesMenuGroupTypeCbx.bottomAnchor, constant: 10).isActive = true
        showVolumeCheckBox.leadingAnchor.constraint(equalTo: favoritesMenuGroupTypeCbx.leadingAnchor).isActive = true

        showMuteCheckBox.translatesAutoresizingMaskIntoConstraints = false
        showMuteCheckBox.topAnchor.constraint(equalTo: showVolumeCheckBox.bottomAnchor, constant: 10).isActive = true
        showMuteCheckBox.leadingAnchor.constraint(equalTo: favoritesMenuGroupTypeCbx.leadingAnchor).isActive = true

        showCopyToClipboardCheckBox.translatesAutoresizingMaskIntoConstraints = false
        showCopyToClipboardCheckBox.topAnchor.constraint(equalTo: showMuteCheckBox.bottomAnchor, constant: 10).isActive = true
        showCopyToClipboardCheckBox.leadingAnchor.constraint(equalTo: favoritesMenuGroupTypeCbx.leadingAnchor).isActive = true

        var separator = Separator()
        res.addSubview(separator)
        separator.topAnchor.constraint(equalTo: showCopyToClipboardCheckBox.bottomAnchor, constant: 24).isActive = true
        separator.leadingAnchor.constraint(equalTo: res.leadingAnchor, constant: 20).isActive = true
        separator.trailingAnchor.constraint(equalTo: res.trailingAnchor, constant: -20).isActive = true

        showToolTipCheckBox.translatesAutoresizingMaskIntoConstraints = false
        showToolTipCheckBox.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 10).isActive = true
        showToolTipCheckBox.leadingAnchor.constraint(equalTo: favoritesMenuGroupTypeCbx.leadingAnchor).isActive = true

        separator = Separator()
        res.addSubview(separator)
        separator.topAnchor.constraint(equalTo: showToolTipCheckBox.bottomAnchor, constant: 24).isActive = true
        separator.leadingAnchor.constraint(equalTo: res.leadingAnchor, constant: 20).isActive = true
        separator.trailingAnchor.constraint(equalTo: res.trailingAnchor, constant: -20).isActive = true

        var last = initNotificationViews(tab: res, prev: separator)

        res.bottomAnchor.constraint(equalTo: last.bottomAnchor, constant: 32).isActive = true

        for v in res.subviews {
            res.trailingAnchor.constraint(greaterThanOrEqualTo: v.trailingAnchor, constant: 20).isActive = true
        }

        return res
    }

    /* ****************************************
     *
     * ****************************************/
    private func initNotificationViews(tab: NSView, prev: NSView) -> NSView {
        tab.addSubview(notifiactionsLabel)

        notifiactionsLabel.alignment = .right
        notifiactionsLabel.translatesAutoresizingMaskIntoConstraints = false
        notifiactionsLabel.topAnchor.constraint(equalToSystemSpacingBelow: prev.bottomAnchor, multiplier: 1).isActive = true
        notifiactionsLabel.leadingAnchor.constraint(equalTo: favoritesMenuGroupTypeLabel.leadingAnchor).isActive = true
        notifiactionsLabel.trailingAnchor.constraint(equalTo: favoritesMenuGroupTypeLabel.trailingAnchor).isActive = true

        tab.addSubview(notificationsWhenPlaybackStarts)
        notificationsWhenPlaybackStarts.translatesAutoresizingMaskIntoConstraints = false
        notificationsWhenPlaybackStarts.centerYAnchor.constraint(equalTo: notifiactionsLabel.centerYAnchor).isActive = true
        notificationsWhenPlaybackStarts.leadingAnchor.constraint(equalTo: favoritesMenuGroupTypeCbx.leadingAnchor).isActive = true

        notificationsWhenPlaybackStarts.state = settings.showNotificationWhenPlaybackStarts ? .on : .off
        notificationsWhenPlaybackStarts.target = self
        notificationsWhenPlaybackStarts.action = #selector(notificationsWhenPlaybackStartsChanged)

        return notificationsWhenPlaybackStarts
    }

    /* ****************************************
     *
     * ****************************************/
    private func initFavoritesMenuGroupTypeCbx() {
        favoritesMenuGroupTypeCbx.removeAllItems()

        favoritesMenuGroupTypeCbx.addItem(withTitle: NSLocalizedString("as a flat list", tableName: "Settings", comment: "Settings label"))
        favoritesMenuGroupTypeCbx.lastItem?.tag = Settings.FavoritesMenuType.flat.rawValue

        favoritesMenuGroupTypeCbx.addItem(withTitle: NSLocalizedString("with margins", tableName: "Settings", comment: "Settings label"))
        favoritesMenuGroupTypeCbx.lastItem?.tag = Settings.FavoritesMenuType.margin.rawValue

        favoritesMenuGroupTypeCbx.addItem(withTitle: NSLocalizedString("as a submenu", tableName: "Settings", comment: "Settings label"))
        favoritesMenuGroupTypeCbx.lastItem?.tag = Settings.FavoritesMenuType.submenu.rawValue

        favoritesMenuGroupTypeCbx.target = self
        favoritesMenuGroupTypeCbx.action = #selector(favoritesMenuGroupTypeChanged)
        favoritesMenuGroupTypeCbx.selectItem(withTag: settings.favoritesMenuType.rawValue)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func favoritesMenuGroupTypeChanged(_ sender: Any) {
        if let type = Settings.FavoritesMenuType(rawValue: favoritesMenuGroupTypeCbx.selectedItem?.tag ?? 0) {
            settings.favoritesMenuType = type
            NotificationCenter.default.post(name: Notification.Name.SettingsChanged, object: nil)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func showVolumeChanged(_ sender: NSButton) {
        settings.showVolumeInMenu = showVolumeCheckBox.state == .on
        NotificationCenter.default.post(name: Notification.Name.SettingsChanged, object: nil)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func showMuteCheckBoxChanged(_ sender: NSButton) {
        settings.showMuteInMenu = sender.state == .on
        NotificationCenter.default.post(name: Notification.Name.SettingsChanged, object: nil)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func showTooltipChanged(_ sender: NSButton) {
        settings.showTooltip = sender.state == .on
        NotificationCenter.default.post(name: Notification.Name.SettingsChanged, object: nil)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func showCopyToClipboardChanged(_ sender: NSButton) {
        settings.showCopyToClipboardInMenu = sender.state == .on
        NotificationCenter.default.post(name: Notification.Name.SettingsChanged, object: nil)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func notificationsWhenPlaybackStartsChanged(_ sender: NSButton) {
        settings.showNotificationWhenPlaybackStarts = sender.state == .on
        NotificationCenter.default.post(name: Notification.Name.SettingsChanged, object: nil)
    }
}
