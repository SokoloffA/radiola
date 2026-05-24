//
//  AdvancedPage.swift
//  Radiola
//
// Created by Alex Sokolov on 23.07.2022.
//

import Cocoa

class AdvancedPage: PreferencesPage {
    private let startupLabel = NSLocalizedString("Startup:", tableName: "Settings", comment: "Settings label")
    private let playLastStationCheckBox = Checkbox(title: NSLocalizedString("Play last station on startup", tableName: "Settings", comment: "Settings control title"))
    private let showMainWindowOnStartupCheckBox = Checkbox(title: NSLocalizedString("Open the main window on startup", tableName: "Settings", comment: "Settings control title"))

    private let proxyLabel = NSLocalizedString("HTTP(S) proxy:", tableName: "Settings", comment: "Settings label")
    private let proxyEdit = TextEdit()

    /* ****************************************
     *
     * ****************************************/
    override init() {
        super.init()
        title = NSLocalizedString("Advanced", tableName: "Settings", comment: "Settings page title")

        addRow(title: startupLabel, rightView: playLastStationCheckBox)
        addRow(rightView: showMainWindowOnStartupCheckBox)
        addSeparator()
        addRow(title: proxyLabel, rightView: proxyEdit)

        initPlayLastStationCbx()

        showMainWindowOnStartupCheckBox.state = settings.showMainWindowOnStartup ? .on : .off
        showMainWindowOnStartupCheckBox.target = self
        showMainWindowOnStartupCheckBox.action = #selector(showMainWindowOnStartupCheckBoxChanged)

        proxyEdit.placeholderString = "http://127.0.0.1:1316"
        proxyEdit.stringValue = settings.proxy ?? ""
        proxyEdit.target = self
        proxyEdit.action = #selector(proxyChanged)
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
    private func initPlayLastStationCbx() {
        playLastStationCheckBox.state = settings.playLastStation ? .on : .off
        playLastStationCheckBox.target = self
        playLastStationCheckBox.action = #selector(playLastStationCbxChanged)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func playLastStationCbxChanged() {
        settings.playLastStation = playLastStationCheckBox.state == .on
        NotificationCenter.default.post(name: Notification.Name.SettingsChanged, object: nil)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func showMainWindowOnStartupCheckBoxChanged(_ sender: NSButton) {
        settings.showMainWindowOnStartup = sender.state == .on
        NotificationCenter.default.post(name: Notification.Name.SettingsChanged, object: nil)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func proxyChanged(_ sender: NSTextField) {
        settings.proxy = proxyEdit.stringValue != "" ? proxyEdit.stringValue : nil
        AppState.shared.applyProxySettings()
        NotificationCenter.default.post(name: Notification.Name.SettingsChanged, object: nil)
    }
}
