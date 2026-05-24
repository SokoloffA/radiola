//
//  ControlsPage.swift
//  Radiola
//
//  Created by Alex Sokolov on 02.07.2023.
//

import Cocoa

fileprivate struct GlobalKeyDef {
    var key: KeyboardShortcuts.Name
    var label: String
}

class ControlsPage: PreferencesPage {
    private var leftMouseButtonLbl = NSLocalizedString("Left mouse button:", tableName: "Settings", comment: "Settings label")
    private var middleMouseButtonLbl = NSLocalizedString("Middle mouse button:", tableName: "Settings", comment: "Settings label")
    private var rightMouseButtonLbl = NSLocalizedString("Right mouse button:", tableName: "Settings", comment: "Settings label")
    private var wheellMouseLbl = NSLocalizedString("Mouse wheel:", tableName: "Settings", comment: "Settings label")

    private var leftMouseButtonCbx = NSPopUpButton()
    private var middleMouseButtonCbx = NSPopUpButton()
    private var rightMouseButtonCbx = NSPopUpButton()
    private var wheellMouseCbx = NSPopUpButton()

    private var ctrlMouseHelp = Label()

    private var mediaKeysHandlingLbl = NSLocalizedString("Media key handling:", tableName: "Settings", comment: "Settings label")
    private var mediaKeysHandlingCbx = NSPopUpButton()

    private var mediaPrevNextButtonLbl = Label(text: NSLocalizedString("Previous and next track buttons:", tableName: "Settings", comment: "Settings label"))
    private var mediaPrevNextButtonCbx = NSPopUpButton()

    private var globalKeys: [GlobalKeyDef] = [
        GlobalKeyDef(key: .showMainWindow, label: NSLocalizedString("Global shortcut to show stations", tableName: "Settings", comment: "Settings label")),
        GlobalKeyDef(key: .showHistoryWindow, label: NSLocalizedString("Global shortcut to show history", tableName: "Settings", comment: "Settings label")),
        GlobalKeyDef(key: .showMainMenu, label: NSLocalizedString("Global shortcut to show menu", tableName: "Settings", comment: "Settings label")),
        GlobalKeyDef(key: .togglePlayPuse, label: NSLocalizedString("Global shortcut to toggle play and pause", tableName: "Settings", comment: "Settings label")),
    ]

    /* ****************************************
     *
     * ****************************************/
    override init() {
        super.init()
        title = NSLocalizedString("Controls", tableName: "Settings", comment: "Settings page title")

        mediaPrevNextButtonLbl.alignment = .right
        ctrlMouseHelp.stringValue = NSLocalizedString("You can always open the menu with Control+Mouse Click", tableName: "Settings", comment: "Settings label")
        ctrlMouseHelp.textColor = .secondaryLabelColor

        addRow(title: leftMouseButtonLbl, rightView: leftMouseButtonCbx)
        addRow(title: middleMouseButtonLbl, rightView: middleMouseButtonCbx)
        addRow(title: rightMouseButtonLbl, rightView: rightMouseButtonCbx)
        addRow(rightView: ctrlMouseHelp).bottomPadding = 20
        addRow(title: wheellMouseLbl, rightView: wheellMouseCbx)
        addSeparator()
        addRow(title: mediaKeysHandlingLbl, rightView: mediaKeysHandlingCbx)
        addRow(leftView: mediaPrevNextButtonLbl, rightView: mediaPrevNextButtonCbx)
        addGlobalKeys()

        initButtonCbx(leftMouseButtonCbx, button: .left)
        initButtonCbx(middleMouseButtonCbx, button: .middle)
        initButtonCbx(rightMouseButtonCbx, button: .right)

        initMouseWheelCbx()

        initMediaKeysCbx()
        initMediaPrevNextButtonCbx()
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
    private func addGlobalKeys() {
        for globKeyDef in globalKeys {
            let ctrl = KeyboardShortcuts.RecorderCocoa(for: globKeyDef.key)
            ctrl.pressShortcutText = NSLocalizedString("Press shortcut", tableName: "Settings", comment: "Settings label")
            ctrl.recordShortcutText = NSLocalizedString("Record shortcut", tableName: "Settings", comment: "Settings label")

            addRow(title: globKeyDef.label, rightView: ctrl)
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func initButtonCbx(_ cbx: NSPopUpButton, button: MouseButton) {
        cbx.tag = button.rawValue

        cbx.removeAllItems()
        cbx.addItem(withTitle: NSLocalizedString("shows the popup menu", tableName: "Settings", comment: "Settings combobox item"))
        cbx.lastItem?.tag = MouseButtonAction.showMenu.rawValue

        cbx.addItem(withTitle: NSLocalizedString("toggles playback and pause", tableName: "Settings", comment: "Settings combobox item"))
        cbx.lastItem?.tag = MouseButtonAction.playPause.rawValue

        cbx.addItem(withTitle: NSLocalizedString("shows the main window", tableName: "Settings", comment: "Settings combobox item"))
        cbx.lastItem?.tag = MouseButtonAction.showMainWindow.rawValue

        cbx.addItem(withTitle: NSLocalizedString("shows the history", tableName: "Settings", comment: "Settings combobox item"))
        cbx.lastItem?.tag = MouseButtonAction.showHistory.rawValue

        cbx.addItem(withTitle: NSLocalizedString("toggles mute", tableName: "Settings", comment: "Settings combobox item"))
        cbx.lastItem?.tag = MouseButtonAction.mute.rawValue

        cbx.addItem(withTitle: NSLocalizedString("mark current song as favorite", tableName: "Settings", comment: "Settings combobox item"))
        cbx.lastItem?.tag = MouseButtonAction.markAsFavorite.rawValue

        cbx.selectItem(withTag: settings.mouseAction(forButton: button).rawValue)
        cbx.target = self
        cbx.action = #selector(buttonActionChanged)
    }

    /* ****************************************
     *
     * ****************************************/
    private func initMouseWheelCbx() {
        let cbx = wheellMouseCbx

        cbx.removeAllItems()

        cbx.addItem(withTitle: NSLocalizedString("does nothing", tableName: "Settings", comment: "Settings combobox item"))
        cbx.lastItem?.tag = MouseWheelAction.nothing.rawValue

        cbx.addItem(withTitle: NSLocalizedString("changes the volume", tableName: "Settings", comment: "Settings combobox item"))
        cbx.lastItem?.tag = MouseWheelAction.volume.rawValue

        cbx.selectItem(withTag: settings.mouseWheelAction.rawValue)
        cbx.target = self
        cbx.action = #selector(mouseWheelCbxChanged)
    }

    /* ****************************************
     *
     * ****************************************/
    private func initMediaKeysCbx() {
        let cbx = mediaKeysHandlingCbx

        cbx.removeAllItems()

        cbx.addItem(withTitle: NSLocalizedString("never", tableName: "Settings", comment: "Settings combobox item"))
        cbx.lastItem?.tag = Settings.MediaKeysHandleType.disable.rawValue

        cbx.addItem(withTitle: NSLocalizedString("always", tableName: "Settings", comment: "Settings combobox item"))
        cbx.lastItem?.tag = Settings.MediaKeysHandleType.enable.rawValue

        cbx.addItem(withTitle: NSLocalizedString("when the main window is open", tableName: "Settings", comment: "Settings combobox item"))
        cbx.lastItem?.tag = Settings.MediaKeysHandleType.mainWindowActive.rawValue

        cbx.selectItem(withTag: settings.mediaKeysHandle.rawValue)
        cbx.target = self
        cbx.action = #selector(multimediaKeysHandleChanged)
        refresh()
    }

    /* ****************************************
     *
     * ****************************************/
    private func initMediaPrevNextButtonCbx() {
        mediaPrevNextButtonCbx.removeAllItems()

        mediaPrevNextButtonCbx.addItem(withTitle: NSLocalizedString("does nothing", tableName: "Settings", comment: "Settings combobox item"))
        mediaPrevNextButtonCbx.lastItem?.tag = MediaPrevNextKeyAction.disable.rawValue

        mediaPrevNextButtonCbx.addItem(withTitle: NSLocalizedString("switch favorite stations", tableName: "Settings", comment: "Settings combobox item"))
        mediaPrevNextButtonCbx.lastItem?.tag = MediaPrevNextKeyAction.switchStation.rawValue

        mediaPrevNextButtonCbx.selectItem(withTag: settings.mediaPrevNextKeyAction.rawValue)
        mediaPrevNextButtonCbx.target = self
        mediaPrevNextButtonCbx.action = #selector(mediaPrevNextButtonCbxChanged)
        refresh()
    }

    /* ****************************************
     *
     * ****************************************/
    private func refresh() {
        mediaPrevNextButtonCbx.isEnabled = settings.mediaKeysHandle != .disable
        mediaPrevNextButtonLbl.isEnabled = mediaPrevNextButtonCbx.isEnabled
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
    @objc func mouseWheelCbxChanged(_ sender: NSPopUpButton) {
        guard
            let tag = sender.selectedItem?.tag,
            let val = MouseWheelAction(rawValue: tag)
        else {
            return
        }

        settings.mouseWheelAction = val
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func multimediaKeysHandleChanged(_ sender: NSPopUpButton) {
        guard
            let tag = sender.selectedItem?.tag,
            let val = Settings.MediaKeysHandleType(rawValue: tag)
        else {
            return
        }

        settings.mediaKeysHandle = val
        refresh()
    }

    /* ****************************************
     *
     * ****************************************/
    @objc func mediaPrevNextButtonCbxChanged(_ sender: NSPopUpButton) {
        guard
            let tag = sender.selectedItem?.tag,
            let val = MediaPrevNextKeyAction(rawValue: tag)
        else {
            return
        }

        settings.mediaPrevNextKeyAction = val
        refresh()
    }
}
