//
//  AppearancePage.swift
//  Radiola
//
//  Created by Alex Sokolov on 02.07.2023.
//

import Cocoa

class AppearancePage: PreferencesPage {
    private let favoritesMenuGroupTypeLabel = NSLocalizedString("Show groups in favorites:", tableName: "Settings", comment: "Settings label")
    private let favoritesMenuGroupTypeCbx = NSPopUpButton()
    private let showVolumeCheckBox = Checkbox(title: NSLocalizedString("Show the volume control in the menu", tableName: "Settings", comment: "Settings label"))
    private let showMuteCheckBox = Checkbox(title: NSLocalizedString("Show the mute item in the menu", tableName: "Settings", comment: "Settings label"))
    private let showCopyToClipboardCheckBox = Checkbox(title: NSLocalizedString("Show the \"Copy song title and artist\" item in the menu", tableName: "Settings", comment: "Settings label"))
    private let showToolTipCheckBox = Checkbox(title: NSLocalizedString("Show a tooltip with the radiostation and song", tableName: "Settings", comment: "Settings label"))
    private let showSongInStatusBarLabel = NSLocalizedString("Show song title in menu bar", tableName: "Settings", comment: "Settings label")
    private let showSongInStatusBarEdit = NSPopUpButton()

    private let notifiactionsLabel = NSLocalizedString("Notifications:", tableName: "Settings", comment: "Settings label")
    private let notificationsWhenPlaybackStarts = Checkbox(title: NSLocalizedString("When playback starts.", tableName: "Settings", comment: "Settings label"))

    private let songInStatusBarWidthLabel = NSLocalizedString("Maximum width of the text in the menu bar:", tableName: "Settings", comment: "Settings label")
    private let songInStatusBarWidthEdit = SpinBox()
    private let songInStatusBarUnitLabel = NSLocalizedString("pixels", tableName: "Settings", comment: "Settings label")

    /* ****************************************
     *
     * ****************************************/
    override init() {
        super.init()

        title = NSLocalizedString("Appearance", tableName: "Settings", comment: "Settings page title")

        addRow(title: favoritesMenuGroupTypeLabel, rightView: favoritesMenuGroupTypeCbx)
        addRow(rightView: showVolumeCheckBox)
        addRow(rightView: showMuteCheckBox)
        addRow(rightView: showCopyToClipboardCheckBox)
        addSeparator()
        addRow(rightView: showToolTipCheckBox)
        addRow(title: showSongInStatusBarLabel, rightView: showSongInStatusBarEdit)
        addRow(title: songInStatusBarWidthLabel, rightViews: [songInStatusBarWidthEdit, Label(text: songInStatusBarUnitLabel)])
        addSeparator()
        addRow(title: notifiactionsLabel, rightView: notificationsWhenPlaybackStarts)

        initFavoritesMenuGroupTypeCbx()
        favoritesMenuGroupTypeCbx.target = self
        favoritesMenuGroupTypeCbx.action = #selector(favoritesMenuGroupTypeChanged)
        favoritesMenuGroupTypeCbx.selectItem(withTag: settings.favoritesMenuType.rawValue)

        showVolumeCheckBox.state = settings.showVolumeInMenu ? .on : .off
        showVolumeCheckBox.target = self
        showVolumeCheckBox.action = #selector(showVolumeChanged)

        showMuteCheckBox.state = settings.showMuteInMenu ? .on : .off
        showMuteCheckBox.target = self
        showMuteCheckBox.action = #selector(showMuteCheckBoxChanged)

        showToolTipCheckBox.state = settings.showTooltip ? .on : .off
        showToolTipCheckBox.target = self
        showToolTipCheckBox.action = #selector(showTooltipChanged)

        initShowSongInStatusBarEdit()
        showSongInStatusBarEdit.selectItem(withTag: settings.showSongInStatusBar.rawValue)
        showSongInStatusBarEdit.target = self
        showSongInStatusBarEdit.action = #selector(showSongInStatusBarChanged)

        songInStatusBarWidthEdit.minValue = 100
        songInStatusBarWidthEdit.maxValue = 500
        songInStatusBarWidthEdit.increment = 10
        songInStatusBarWidthEdit.integerValue = settings.songInStatusBarWidth
        songInStatusBarWidthEdit.target = self
        songInStatusBarWidthEdit.action = #selector(songInStatusBarWidthChanged)

        showCopyToClipboardCheckBox.state = settings.showCopyToClipboardInMenu ? .on : .off
        showCopyToClipboardCheckBox.target = self
        showCopyToClipboardCheckBox.action = #selector(showCopyToClipboardChanged)

        notificationsWhenPlaybackStarts.state = settings.showNotificationWhenPlaybackStarts ? .on : .off
        notificationsWhenPlaybackStarts.target = self
        notificationsWhenPlaybackStarts.action = #selector(notificationsWhenPlaybackStartsChanged)
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
    private func initFavoritesMenuGroupTypeCbx() {
        favoritesMenuGroupTypeCbx.removeAllItems()

        favoritesMenuGroupTypeCbx.addItem(withTitle: NSLocalizedString("as a flat list", tableName: "Settings", comment: "Settings label"))
        favoritesMenuGroupTypeCbx.lastItem?.tag = Settings.FavoritesMenuType.flat.rawValue

        favoritesMenuGroupTypeCbx.addItem(withTitle: NSLocalizedString("with margins", tableName: "Settings", comment: "Settings label"))
        favoritesMenuGroupTypeCbx.lastItem?.tag = Settings.FavoritesMenuType.margin.rawValue

        favoritesMenuGroupTypeCbx.addItem(withTitle: NSLocalizedString("as a submenu", tableName: "Settings", comment: "Settings label"))
        favoritesMenuGroupTypeCbx.lastItem?.tag = Settings.FavoritesMenuType.submenu.rawValue
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
    private func initShowSongInStatusBarEdit() {
        showSongInStatusBarEdit.removeAllItems()

        showSongInStatusBarEdit.addItem(
            withTitle: NSLocalizedString("never", tableName: "Settings", comment: "Settings combobox item"),
            tag: ShowSongInStatusBar.never.rawValue)

        showSongInStatusBarEdit.addItem(
            withTitle: NSLocalizedString("always", tableName: "Settings", comment: "Settings combobox item"),
            tag: ShowSongInStatusBar.always.rawValue)

        let cases = ShowSongInStatusBar.allCases.sorted { $0.rawValue < $1.rawValue }
        for c in cases {
            if c == .never || c == .always {
                continue
            }

            let s = NSLocalizedString("if screen width exceeds %d px", tableName: "Settings", comment: "Settings combobox item")
            showSongInStatusBarEdit.addItem(
                withTitle: String(format: s, c.rawValue),
                tag: c.rawValue)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func showSongInStatusBarChanged(_ sender: NSPopUpButton) {
        guard
            let tag = sender.selectedItem?.tag,
            let val = ShowSongInStatusBar(rawValue: tag)
        else {
            return
        }

        settings.showSongInStatusBar = val
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

    /* ****************************************
     *
     * ****************************************/
    @objc func songInStatusBarWidthChanged(_ sender: Any) {
        settings.songInStatusBarWidth = songInStatusBarWidthEdit.integerValue
        NotificationCenter.default.post(name: Notification.Name.SettingsChanged, object: nil)
    }
}
