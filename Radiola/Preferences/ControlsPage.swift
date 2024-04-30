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

    /* ****************************************
     *
     * ****************************************/
    override func viewDidLoad() {
        title = "Controls"
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
    private func createView() -> NSView {
        let res = NSView()

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

        leftMouseButtonLbl.stringValue = "Left mouse button:"
        leftMouseButtonLbl.alignment = .right
        leftMouseButtonLbl.translatesAutoresizingMaskIntoConstraints = false
        leftMouseButtonCbx.translatesAutoresizingMaskIntoConstraints = false
        leftMouseButtonCbx.topAnchor.constraint(equalTo: res.topAnchor, constant: 20).isActive = true
        leftMouseButtonLbl.leadingAnchor.constraint(equalTo: res.leadingAnchor, constant: 16).isActive = true
        leftMouseButtonCbx.leadingAnchor.constraint(equalTo: leftMouseButtonLbl.trailingAnchor, constant: 20).isActive = true
        leftMouseButtonLbl.centerYAnchor.constraint(equalTo: leftMouseButtonCbx.centerYAnchor).isActive = true

        middleMouseButtonLbl.stringValue = "Middle mouse button:"
        alignRow(lbl: middleMouseButtonLbl, cbx: middleMouseButtonCbx, prev: leftMouseButtonCbx)

        rightMouseButtonLbl.stringValue = "Right mouse button:"
        alignRow(lbl: rightMouseButtonLbl, cbx: rightMouseButtonCbx, prev: middleMouseButtonCbx)

        ctrlMouseHelp.stringValue = "You can always open the menu with Control+Mouse Click"
        ctrlMouseHelp.textColor = .secondaryLabelColor
        ctrlMouseHelp.translatesAutoresizingMaskIntoConstraints = false
        ctrlMouseHelp.topAnchor.constraint(equalTo: rightMouseButtonCbx.bottomAnchor, constant: 14).isActive = true
        ctrlMouseHelp.leadingAnchor.constraint(equalTo: rightMouseButtonCbx.leadingAnchor).isActive = true
        ctrlMouseHelp.trailingAnchor.constraint(equalTo: rightMouseButtonCbx.trailingAnchor).isActive = true

        wheellMouseLbl.stringValue = "Mouse wheel:"
        alignRow(lbl: wheellMouseLbl, cbx: wheellMouseCbx, prev: ctrlMouseHelp, margin: 24)

        let separator = Separator()
        res.addSubview(separator)
        separator.topAnchor.constraint(equalTo: wheellMouseCbx.bottomAnchor, constant: 24).isActive = true
        separator.leadingAnchor.constraint(equalTo: res.leadingAnchor, constant: 20).isActive = true
        separator.trailingAnchor.constraint(equalTo: res.trailingAnchor, constant: -20).isActive = true

        mediaKeysHandlingLbl.stringValue = "Media key handling:"
        alignRow(lbl: mediaKeysHandlingLbl, cbx: mediaKeysHandlingCbx, prev: separator, margin: 20)

        mediaPrevNextButtonLbl.stringValue = "Previous and next track buttons:"
        alignRow(lbl: mediaPrevNextButtonLbl, cbx: mediaPrevNextButtonCbx, prev: mediaKeysHandlingCbx)

        res.bottomAnchor.constraint(equalTo: mediaPrevNextButtonCbx.bottomAnchor, constant: 32).isActive = true
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
        cbx.addItem(withTitle: "shows the popup menu")
        cbx.lastItem?.tag = MouseButtonAction.showMenu.rawValue

        cbx.addItem(withTitle: "toggles playback and pause")
        cbx.lastItem?.tag = MouseButtonAction.playPause.rawValue

        cbx.addItem(withTitle: "shows the main window")
        cbx.lastItem?.tag = MouseButtonAction.showMainWindow.rawValue

        cbx.addItem(withTitle: "shows the history")
        cbx.lastItem?.tag = MouseButtonAction.showHistory.rawValue

        cbx.addItem(withTitle: "toggles mute")
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

        cbx.addItem(withTitle: "does nothing")
        cbx.lastItem?.tag = MouseWheelAction.nothing.rawValue

        cbx.addItem(withTitle: "changes the volume")
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

        cbx.addItem(withTitle: "never")
        cbx.lastItem?.tag = Settings.MediaKeysHandleType.disable.rawValue

        cbx.addItem(withTitle: "always")
        cbx.lastItem?.tag = Settings.MediaKeysHandleType.enable.rawValue

        cbx.addItem(withTitle: "when the main window is open")
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

        mediaPrevNextButtonCbx.addItem(withTitle: "does nothing")
        mediaPrevNextButtonCbx.lastItem?.tag = MediaPrevNextKeyAction.disable.rawValue

        mediaPrevNextButtonCbx.addItem(withTitle: "switch favorite stations")
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
