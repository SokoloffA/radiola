//
//  AdvancedPage.swift
//  Radiola
//
// Created by Alex Sokolov on 23.07.2022.
//

import Cocoa

class AdvancedPage: NSViewController {
    private let startupLabel = Label(text: NSLocalizedString("Startup:", tableName: "Settings", comment: "Settings label"))
    private let playLastStationCheckBox = Checkbox(title: NSLocalizedString("Play last station on startup", tableName: "Settings", comment: "Settings control title"))
    private let showMainWindowOnStartupCheckBox = Checkbox(title: NSLocalizedString("Open the main window on startup", tableName: "Settings", comment: "Settings control title"))

    private let proxyLabel = Label(text: NSLocalizedString("HTTP(S) proxy:", tableName: "Settings", comment: "Settings label"))
    private let proxyEdit = TextEdit()

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(nibName: nil, bundle: nil)
        title = NSLocalizedString("Advanced", tableName: "Settings", comment: "Settings page title")
        view = createView()

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
    private func createView() -> NSView {
        let res = NSView()
        res.autoresizingMask = [.maxXMargin, .minYMargin]

        res.addSubview(startupLabel)
        startupLabel.alignment = .right
        startupLabel.translatesAutoresizingMaskIntoConstraints = false
        startupLabel.topAnchor.constraint(equalToSystemSpacingBelow: res.topAnchor, multiplier: 1).isActive = true
        startupLabel.leadingAnchor.constraint(equalTo: res.leadingAnchor, constant: 16).isActive = true

        res.addSubview(playLastStationCheckBox)
        playLastStationCheckBox.translatesAutoresizingMaskIntoConstraints = false
        playLastStationCheckBox.centerYAnchor.constraint(equalTo: startupLabel.centerYAnchor).isActive = true
        playLastStationCheckBox.leadingAnchor.constraint(equalToSystemSpacingAfter: startupLabel.trailingAnchor, multiplier: 1).isActive = true
        res.trailingAnchor.constraint(greaterThanOrEqualTo: playLastStationCheckBox.trailingAnchor, constant: 16).isActive = true

        res.addSubview(showMainWindowOnStartupCheckBox)
        showMainWindowOnStartupCheckBox.translatesAutoresizingMaskIntoConstraints = false
        showMainWindowOnStartupCheckBox.topAnchor.constraint(equalToSystemSpacingBelow: playLastStationCheckBox.bottomAnchor, multiplier: 1).isActive = true
        showMainWindowOnStartupCheckBox.leadingAnchor.constraint(equalTo: playLastStationCheckBox.leadingAnchor).isActive = true
        showMainWindowOnStartupCheckBox.trailingAnchor.constraint(equalTo: playLastStationCheckBox.trailingAnchor).isActive = true

        let separator = Separator()
        res.addSubview(separator)
        separator.topAnchor.constraint(equalTo: showMainWindowOnStartupCheckBox.bottomAnchor, constant: 24).isActive = true
        separator.leadingAnchor.constraint(equalTo: res.leadingAnchor, constant: 20).isActive = true
        separator.trailingAnchor.constraint(equalTo: res.trailingAnchor, constant: -20).isActive = true

        res.addSubview(proxyLabel)
        proxyLabel.alignment = .right
        proxyLabel.translatesAutoresizingMaskIntoConstraints = false
        proxyLabel.topAnchor.constraint(equalToSystemSpacingBelow: separator.bottomAnchor, multiplier: 1).isActive = true
        proxyLabel.leadingAnchor.constraint(equalTo: startupLabel.leadingAnchor).isActive = true
        proxyLabel.trailingAnchor.constraint(equalTo: startupLabel.trailingAnchor).isActive = true

        res.addSubview(proxyEdit)
        proxyEdit.translatesAutoresizingMaskIntoConstraints = false
        proxyEdit.centerYAnchor.constraint(equalTo: proxyLabel.centerYAnchor).isActive = true
        proxyEdit.leadingAnchor.constraint(equalTo: playLastStationCheckBox.leadingAnchor).isActive = true
        res.trailingAnchor.constraint(equalToSystemSpacingAfter: proxyEdit.trailingAnchor, multiplier: 1).isActive = true

        res.bottomAnchor.constraint(equalTo: proxyEdit.bottomAnchor, constant: 32).isActive = true

        return res
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
