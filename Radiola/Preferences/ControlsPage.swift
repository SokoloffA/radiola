//
//  ControlsPage.swift
//  Radiola
//
//  Created by Alex Sokolov on 02.07.2023.
//

import Cocoa

class ControlsPage: NSViewController {
    @IBOutlet var leftMouseButtonCbx: NSPopUpButton!
    @IBOutlet var middleMouseButtonCbx: NSPopUpButton!
    @IBOutlet var rightMouseButtonCbx: NSPopUpButton!
    @IBOutlet var wheellMouseCbx: NSPopUpButton!

    @IBOutlet var mediaKeysHandlingCbx: NSPopUpButton!
    @IBOutlet var mediaPrevNextButtonCbx: NSPopUpButton!
    @IBOutlet var mediaPrevNextButtonLabel: NSPopUpButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Controls"

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
        guard let cbx = wheellMouseCbx else { return }

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
        guard let cbx = mediaKeysHandlingCbx else { return }

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
        mediaPrevNextButtonLabel.isEnabled = mediaPrevNextButtonCbx.isEnabled
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
