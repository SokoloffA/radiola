//
//  AppearancePage.swift
//  Radiola
//
//  Created by Alex Sokolov on 02.07.2023.
//

import Cocoa

class AppearancePage: NSViewController {
    private let favoritesMenuGroupTypeLabel = Label(text: "Show groups in favorites:")
    private let favoritesMenuGroupTypeCbx = NSPopUpButton()
    private let showVolumeCheckBox = Checkbox(title: "Show the volume control in the menu")
    private let showMuteCheckBox = Checkbox(title: "Show the mute item in the menu")
    private let showCopyToClipboardCheckBox = Checkbox(title: "Show the \"Copy song title and artist\" item in the menu")
    private let showToolTipCheckBox = Checkbox(title: "Show a tooltip with the radiostation and song")

    override func viewDidLoad() {
        title = "Appearance"
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
    private func createView() -> NSView {
        let res = NSView()
        res.autoresizingMask = [.maxXMargin, .minYMargin]

        res.addSubview(favoritesMenuGroupTypeLabel)
        res.addSubview(favoritesMenuGroupTypeCbx)
        res.addSubview(showVolumeCheckBox)
        res.addSubview(showMuteCheckBox)
        res.addSubview(showCopyToClipboardCheckBox)
        res.addSubview(showToolTipCheckBox)

        let secondColAnchor = favoritesMenuGroupTypeCbx.leadingAnchor

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

        let separator = Separator()
        res.addSubview(separator)
        separator.topAnchor.constraint(equalTo: showCopyToClipboardCheckBox.bottomAnchor, constant: 24).isActive = true
        separator.leadingAnchor.constraint(equalTo: res.leadingAnchor, constant: 20).isActive = true
        separator.trailingAnchor.constraint(equalTo: res.trailingAnchor, constant: -20).isActive = true

        showToolTipCheckBox.translatesAutoresizingMaskIntoConstraints = false
        showToolTipCheckBox.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 10).isActive = true
        showToolTipCheckBox.leadingAnchor.constraint(equalTo: favoritesMenuGroupTypeCbx.leadingAnchor).isActive = true

        res.bottomAnchor.constraint(equalTo: showToolTipCheckBox.bottomAnchor, constant: 32).isActive = true

        for v in res.subviews {
            res.trailingAnchor.constraint(greaterThanOrEqualTo: v.trailingAnchor, constant: 20).isActive = true
        }

        return res
    }

    /* ****************************************
     *
     * ****************************************/
    private func initFavoritesMenuGroupTypeCbx() {
        favoritesMenuGroupTypeCbx.removeAllItems()

        favoritesMenuGroupTypeCbx.addItem(withTitle: "as a flat list")
        favoritesMenuGroupTypeCbx.lastItem?.tag = Settings.FavoritesMenuType.flat.rawValue

        favoritesMenuGroupTypeCbx.addItem(withTitle: "with margins")
        favoritesMenuGroupTypeCbx.lastItem?.tag = Settings.FavoritesMenuType.margin.rawValue

        favoritesMenuGroupTypeCbx.addItem(withTitle: "as a submenu")
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
}
