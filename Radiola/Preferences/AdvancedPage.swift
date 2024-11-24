//
//  AdvancedPage.swift
//  Radiola
//
// Created by Alex Sokolov on 23.07.2022.
//

import Cocoa

class AdvancedPage: NSViewController {
    private let playLastStationCheckBox = Checkbox(title: NSLocalizedString("Play last station on startup", tableName: "Settings", comment: "Settings control title"))

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(nibName: nil, bundle: nil)
        title = NSLocalizedString("Advanced", tableName: "Settings", comment: "Settings page title")
        view = createView()

        initPlayLastStationCbx()
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
}
