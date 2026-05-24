//
//  UpdatePanel.swift
//  Radiola
//
//  Created by Alex Sokolov on 23.07.2022.
//

import Cocoa

class UpdatePanel: PreferencesPage {
    private let automaticallyChecksForUpdates = Checkbox(title: NSLocalizedString("Automatically check for updates", tableName: "Settings", comment: "Settings label"))
    private let checkNowButton = NSButton()

    /* ****************************************
     *
     * ****************************************/
    override init() {
        super.init()
        title = NSLocalizedString("Updates", tableName: "Settings", comment: "Settings tab title")

        addRow(rightView: automaticallyChecksForUpdates)
        addRow(rightView: checkNowButton)

        checkNowButton.title = NSLocalizedString("Check for Updates now", tableName: "Settings", comment: "Settings button title")
        checkNowButton.target = updater
        checkNowButton.action = #selector(Updater.checkForUpdates)

        automaticallyChecksForUpdates.state = updater.automaticallyChecksForUpdates ? .on : .off
        automaticallyChecksForUpdates.target = self
        automaticallyChecksForUpdates.action = #selector(autoUpdateClicked)
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
    @objc private func autoUpdateClicked(_ sender: NSButton) {
        updater.automaticallyChecksForUpdates = sender.state == .on
    }
}
