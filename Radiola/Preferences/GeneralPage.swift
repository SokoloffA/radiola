//
//  GeneralPage.swift
//  Radiola
//
//  Created by Alex Sokolov on 03.12.2022.
//

import Cocoa

class GeneralPage: NSViewController {
    @IBOutlet var showVolumeInMenuCheckbox: NSButton!
    @IBOutlet var favoritesMenuGroupTypeCbx: NSPopUpButton!
    @IBOutlet var showVolume: NSButton!

    @IBOutlet var leftButtonCbx: NSPopUpButton!
    @IBOutlet var middleButtonCbx: NSPopUpButton!
    @IBOutlet var rightButtonCbx: NSPopUpButton!

    @IBOutlet var mediaKeysLabel: NSTextField!
    @IBOutlet var mediaKeysCbx: NSPopUpButton!

    /* ****************************************
     *
     * ****************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "General"

        showVolume.state = settings.showVolumeInMenu ? .on : .off

        initFavoritesMenuGroupTypeCbx()
        favoritesMenuGroupTypeCbx.selectItem(withTag: settings.favoritesMenuType.rawValue)

        initButtonCbx(leftButtonCbx, button: .left)
        initButtonCbx(rightButtonCbx, button: .right)
        initButtonCbx(middleButtonCbx, button: .middle)

        initMediaKeysCbx()
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
    }

    /* ****************************************
     *
     * ****************************************/
    private func initButtonCbx(_ cbx: NSPopUpButton, button: MouseButton) {
        cbx.tag = button.rawValue

        cbx.removeAllItems()
        cbx.addItem(withTitle: "shows the popup menu")
        cbx.lastItem?.tag = MouseButtonAction.showMenu.rawValue

        cbx.addItem(withTitle: "toggles playback and pause")
        cbx.lastItem?.tag = MouseButtonAction.playPause.rawValue

        cbx.addItem(withTitle: "shows the main window")
        cbx.lastItem?.tag = MouseButtonAction.showMainWindow.rawValue

        cbx.addItem(withTitle: "shows the history")
        cbx.lastItem?.tag = MouseButtonAction.showHistory.rawValue

        cbx.selectItem(withTag: settings.mouseAction(forButton: button).rawValue)
        cbx.target = self
        cbx.action = #selector(buttonActionChanged)
    }

    /* ****************************************
     *
     * ****************************************/
    private func initMediaKeysCbx() {
        guard let cbx = mediaKeysCbx else { return }

        cbx.removeAllItems()

        cbx.addItem(withTitle: "always")
        cbx.lastItem?.tag = Settings.MediaKeysHandleType.enable.rawValue

        cbx.addItem(withTitle: "never")
        cbx.lastItem?.tag = Settings.MediaKeysHandleType.disable.rawValue

        cbx.addItem(withTitle: "when the main window is open")
        cbx.lastItem?.tag = Settings.MediaKeysHandleType.mainWindowActive.rawValue

        cbx.selectItem(withTag: settings.mediaKeysHandle.rawValue)
        cbx.target = self
        cbx.action = #selector(multimediaKeysHandle)
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func showVolumeChanged(_ sender: NSButton) {
        settings.showVolumeInMenu = showVolume.state == .on
        NotificationCenter.default.post(name: Notification.Name.SettingsChanged, object: nil)
    }

    /* ****************************************
     *
     * ****************************************/
    @IBAction func favoritesMenuGroupTypeChanged(_ sender: Any) {
        if let type = Settings.FavoritesMenuType(rawValue: favoritesMenuGroupTypeCbx.selectedItem?.tag ?? 0) {
            settings.favoritesMenuType = type
            NotificationCenter.default.post(name: Notification.Name.SettingsChanged, object: nil)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func buttonActionChanged(_ sender: NSPopUpButton) {
        guard let btn = MouseButton(rawValue: sender.tag) else { return }
        guard let act = MouseButtonAction(rawValue: sender.selectedItem?.tag ?? 0) else { return }

        settings.setMouseAction(forButton: btn, action: act)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func multimediaKeysHandle(_ sender: NSPopUpButton) {
        guard
            let tag = sender.selectedItem?.tag,
            let val = Settings.MediaKeysHandleType(rawValue: tag)
        else {
            return
        }

        settings.mediaKeysHandle = val
    }
}
