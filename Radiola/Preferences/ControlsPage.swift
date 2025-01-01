//
//  ControlsPage.swift
//  Radiola
//
//  Created by Alex Sokolov on 02.07.2023.
//

import Cocoa

class ControlsPage: NSViewController {
    private var leftMouseButtonLbl = Label()
    private var middleMouseButtonLbl = Label()
    private var rightMouseButtonLbl = Label()
    private var wheellMouseLbl = Label()

    private var leftMouseButtonCbx = NSPopUpButton()
    private var middleMouseButtonCbx = NSPopUpButton()
    private var rightMouseButtonCbx = NSPopUpButton()
    private var wheellMouseCbx = NSPopUpButton()

    private var ctrlMouseHelp = Label()

    private var mediaKeysHandlingLbl = Label()
    private var mediaKeysHandlingCbx = NSPopUpButton()

    private var mediaPrevNextButtonLbl = Label()
    private var mediaPrevNextButtonCbx = NSPopUpButton()

    private var globalKeyShowMainWindowLbl = Label(text: NSLocalizedString("Global shortcut to show stations", tableName: "Settings", comment: "Settings label"))
    private var globalKeyShowMainWindowCtrl = KeyboardShortcuts.RecorderCocoa(for: .showMainWindow)

    private var globalKeyShowHistoryLbl = Label(text: NSLocalizedString("Global shortcut to show history", tableName: "Settings", comment: "Settings label"))
    private var globalKeyShowHistoryCtrl = KeyboardShortcuts.RecorderCocoa(for: .showHistoryWindow)

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(nibName: nil, bundle: nil)

        title = NSLocalizedString("Controls", tableName: "Settings", comment: "Settings page title")
        view = createView()

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
    private func createView() -> NSView {
        let res = NSView()
        res.autoresizingMask = [.maxXMargin, .minYMargin]

        res.addSubview(leftMouseButtonLbl)
        res.addSubview(leftMouseButtonCbx)
        res.addSubview(middleMouseButtonLbl)
        res.addSubview(middleMouseButtonCbx)
        res.addSubview(rightMouseButtonLbl)
        res.addSubview(rightMouseButtonCbx)
        res.addSubview(wheellMouseLbl)
        res.addSubview(wheellMouseCbx)
        res.addSubview(ctrlMouseHelp)
        res.addSubview(mediaKeysHandlingLbl)
        res.addSubview(mediaKeysHandlingCbx)
        res.addSubview(mediaPrevNextButtonLbl)
        res.addSubview(mediaPrevNextButtonCbx)
        res.addSubview(globalKeyShowMainWindowLbl)
        res.addSubview(globalKeyShowMainWindowCtrl)
        res.addSubview(globalKeyShowHistoryLbl)
        res.addSubview(globalKeyShowHistoryCtrl)

        leftMouseButtonLbl.stringValue = NSLocalizedString("Left mouse button:", tableName: "Settings", comment: "Settings label")
        leftMouseButtonLbl.alignment = .right
        leftMouseButtonLbl.translatesAutoresizingMaskIntoConstraints = false
        leftMouseButtonCbx.translatesAutoresizingMaskIntoConstraints = false
        leftMouseButtonCbx.topAnchor.constraint(equalTo: res.topAnchor, constant: 20).isActive = true
        leftMouseButtonLbl.leadingAnchor.constraint(equalTo: res.leadingAnchor, constant: 16).isActive = true
        leftMouseButtonCbx.leadingAnchor.constraint(equalTo: leftMouseButtonLbl.trailingAnchor, constant: 20).isActive = true
        leftMouseButtonLbl.centerYAnchor.constraint(equalTo: leftMouseButtonCbx.centerYAnchor).isActive = true

        middleMouseButtonLbl.stringValue = NSLocalizedString("Middle mouse button:", tableName: "Settings", comment: "Settings label")
        alignRow(lbl: middleMouseButtonLbl, cbx: middleMouseButtonCbx, prev: leftMouseButtonCbx)

        rightMouseButtonLbl.stringValue = NSLocalizedString("Right mouse button:", tableName: "Settings", comment: "Settings label")
        alignRow(lbl: rightMouseButtonLbl, cbx: rightMouseButtonCbx, prev: middleMouseButtonCbx)

        ctrlMouseHelp.stringValue = NSLocalizedString("You can always open the menu with Control+Mouse Click", tableName: "Settings", comment: "Settings label")
        ctrlMouseHelp.textColor = .secondaryLabelColor
        ctrlMouseHelp.translatesAutoresizingMaskIntoConstraints = false
        ctrlMouseHelp.topAnchor.constraint(equalTo: rightMouseButtonCbx.bottomAnchor, constant: 14).isActive = true
        ctrlMouseHelp.leadingAnchor.constraint(equalTo: rightMouseButtonCbx.leadingAnchor).isActive = true
        ctrlMouseHelp.trailingAnchor.constraint(equalTo: rightMouseButtonCbx.trailingAnchor).isActive = true

        wheellMouseLbl.stringValue = NSLocalizedString("Mouse wheel:", tableName: "Settings", comment: "Settings label")
        alignRow(lbl: wheellMouseLbl, cbx: wheellMouseCbx, prev: ctrlMouseHelp, margin: 24)

        let separator = Separator()
        res.addSubview(separator)
        separator.topAnchor.constraint(equalTo: wheellMouseCbx.bottomAnchor, constant: 24).isActive = true
        separator.leadingAnchor.constraint(equalTo: res.leadingAnchor, constant: 20).isActive = true
        separator.trailingAnchor.constraint(equalTo: res.trailingAnchor, constant: -20).isActive = true

        mediaKeysHandlingLbl.stringValue = NSLocalizedString("Media key handling:", tableName: "Settings", comment: "Settings label")
        alignRow(lbl: mediaKeysHandlingLbl, cbx: mediaKeysHandlingCbx, prev: separator, margin: 20)

        mediaPrevNextButtonLbl.stringValue = NSLocalizedString("Previous and next track buttons:", tableName: "Settings", comment: "Settings label")
        alignRow(lbl: mediaPrevNextButtonLbl, cbx: mediaPrevNextButtonCbx, prev: mediaKeysHandlingCbx)

        globalKeyShowMainWindowCtrl.pressShortcutText = NSLocalizedString("Press shortcut", tableName: "Settings", comment: "Settings label")
        globalKeyShowMainWindowCtrl.recordShortcutText = NSLocalizedString("Record shortcut", tableName: "Settings", comment: "Settings label")

        globalKeyShowHistoryCtrl.pressShortcutText = globalKeyShowMainWindowCtrl.pressShortcutText
        globalKeyShowHistoryCtrl.recordShortcutText = globalKeyShowMainWindowCtrl.recordShortcutText

        alignRow(lbl: globalKeyShowMainWindowLbl, cbx: globalKeyShowMainWindowCtrl, prev: mediaPrevNextButtonCbx)
        alignRow(lbl: globalKeyShowHistoryLbl, cbx: globalKeyShowHistoryCtrl, prev: globalKeyShowMainWindowCtrl)

        res.bottomAnchor.constraint(equalTo: globalKeyShowHistoryCtrl.bottomAnchor, constant: 32).isActive = true

        for v in res.subviews {
            res.trailingAnchor.constraint(greaterThanOrEqualTo: v.trailingAnchor, constant: 20).isActive = true
        }

        return res
    }

    /* ****************************************
     *
     * ****************************************/
    private func alignRow(lbl: Label, cbx: NSView, prev: NSView, margin: CGFloat = 10) {
        lbl.alignment = .right

        lbl.translatesAutoresizingMaskIntoConstraints = false
        cbx.translatesAutoresizingMaskIntoConstraints = false

        cbx.topAnchor.constraint(equalTo: prev.bottomAnchor, constant: margin).isActive = true
        cbx.centerYAnchor.constraint(equalTo: lbl.centerYAnchor).isActive = true

        lbl.leadingAnchor.constraint(equalTo: leftMouseButtonLbl.leadingAnchor).isActive = true
        lbl.trailingAnchor.constraint(equalTo: leftMouseButtonLbl.trailingAnchor).isActive = true

        cbx.leadingAnchor.constraint(equalTo: leftMouseButtonCbx.leadingAnchor).isActive = true
        cbx.trailingAnchor.constraint(equalTo: leftMouseButtonCbx.trailingAnchor).isActive = true
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
