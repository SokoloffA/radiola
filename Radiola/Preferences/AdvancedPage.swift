//
//  AdvancedPage.swift
//  Radiola
//
// Created by Alex Sokolov on 23.07.2022.
//

import Cocoa

class AdvancedPage: NSViewController {
    private let playLastStationCheckBox = Checkbox(title: NSLocalizedString("Play last station on startup", tableName: "Settings", comment: "Settings control title"))
    private let showCloudListCheckBox = Checkbox(title: "Show iCloud stations")

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(nibName: nil, bundle: nil)
        title = NSLocalizedString("Advanced", tableName: "Settings", comment: "Settings page title")
        view = createView()

        initPlayLastStationCbx()
        initShowCloudListCheckBox()
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

        res.addSubview(playLastStationCheckBox)

        playLastStationCheckBox.translatesAutoresizingMaskIntoConstraints = false

        playLastStationCheckBox.topAnchor.constraint(equalToSystemSpacingBelow: res.topAnchor, multiplier: 1).isActive = true
        playLastStationCheckBox.leadingAnchor.constraint(equalToSystemSpacingAfter: res.leadingAnchor, multiplier: 1).isActive = true
        res.trailingAnchor.constraint(equalToSystemSpacingAfter: playLastStationCheckBox.trailingAnchor, multiplier: 1).isActive = true

        if isAdvanced() {
            res.addSubview(showCloudListCheckBox)
            showCloudListCheckBox.translatesAutoresizingMaskIntoConstraints = false
            showCloudListCheckBox.topAnchor.constraint(equalToSystemSpacingBelow: playLastStationCheckBox.bottomAnchor, multiplier: 1).isActive = true
            showCloudListCheckBox.leadingAnchor.constraint(equalToSystemSpacingAfter: res.leadingAnchor, multiplier: 1).isActive = true
            res.trailingAnchor.constraint(equalToSystemSpacingAfter: showCloudListCheckBox.trailingAnchor, multiplier: 1).isActive = true
        }

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
    private func isAdvanced() -> Bool {
        let flags = NSEvent.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return flags.contains(.shift)
    }

    /* ****************************************
     *
     * ****************************************/
    private func initShowCloudListCheckBox() {
        showCloudListCheckBox.state = settings.showCloudStations ? .on : .off
        showCloudListCheckBox.target = self
        showCloudListCheckBox.action = #selector(showCloudListCheckBoxChanged)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func showCloudListCheckBoxChanged() {
        settings.showCloudStations = showCloudListCheckBox.state == .on
        NotificationCenter.default.post(name: Notification.Name.SettingsChanged, object: nil)
    }
}
