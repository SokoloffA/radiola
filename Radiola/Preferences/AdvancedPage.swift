//
//  AdvancedPage.swift
//  Radiola
//
// Created by Alex Sokolov on 23.07.2022.
//

import Cocoa

class AdvancedPage: NSViewController {
    private let playLastStationCheckBox = Checkbox(title: NSLocalizedString("Play last station on startup", comment: "Settings control title"))
    private let stationListLabel = Label(text: NSLocalizedString("Show station lists:", comment: "Settings control title"))
    private let stationListComboBox = NSPopUpButton()

    /* ****************************************
     *
     * ****************************************/
    init() {
        super.init(nibName: nil, bundle: nil)
        title = NSLocalizedString("Advanced", comment: "Settings page title")
        view = createView()

        initPlayLastStationCbx()
        initStationListComboBox()
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
        res.addSubview(stationListLabel)
        res.addSubview(stationListComboBox)

        playLastStationCheckBox.translatesAutoresizingMaskIntoConstraints = false
        stationListLabel.translatesAutoresizingMaskIntoConstraints = false
        stationListComboBox.translatesAutoresizingMaskIntoConstraints = false

        playLastStationCheckBox.translatesAutoresizingMaskIntoConstraints = false
        playLastStationCheckBox.topAnchor.constraint(equalToSystemSpacingBelow: res.topAnchor, multiplier: 1).isActive = true
        playLastStationCheckBox.leadingAnchor.constraint(equalTo: stationListComboBox.leadingAnchor).isActive = true
        playLastStationCheckBox.centerXAnchor.constraint(equalTo: res.centerXAnchor).isActive = true

        stationListComboBox.topAnchor.constraint(equalToSystemSpacingBelow: playLastStationCheckBox.bottomAnchor, multiplier: 1).isActive = true
        stationListLabel.centerYAnchor.constraint(equalTo: stationListComboBox.centerYAnchor).isActive = true
        playLastStationCheckBox.leadingAnchor.constraint(equalToSystemSpacingAfter: stationListLabel.trailingAnchor, multiplier: 1).isActive = true

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
    private func initStationListComboBox() {
        stationListComboBox.removeAllItems()

        stationListComboBox.addItem(withTitle: NSLocalizedString("cloud stations only (recommended)", comment: "Settings combobox item"))
        stationListComboBox.lastItem?.tag = Settings.StationsListMode.cloud.rawValue

        stationListComboBox.addItem(withTitle: NSLocalizedString("local stations only", comment: "Settings combobox item"))
        stationListComboBox.lastItem?.tag = Settings.StationsListMode.opml.rawValue

        stationListComboBox.addItem(withTitle: NSLocalizedString("cloud and local stations", comment: "Settings combobox item"))
        stationListComboBox.lastItem?.tag = Settings.StationsListMode.both.rawValue

        stationListComboBox.target = self
        stationListComboBox.action = #selector(stationListComboBoxChanged)

        stationListComboBox.selectItem(withTag: settings.stationsListMode.rawValue)
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func stationListComboBoxChanged() {
        guard let type = Settings.StationsListMode(rawValue: stationListComboBox.selectedTag()) else { return }

        settings.stationsListMode = type
        NotificationCenter.default.post(name: Notification.Name.SettingsChanged, object: nil)
    }
}
