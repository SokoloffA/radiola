//
//  Updater.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 26.07.2022.
//

import Cocoa
import Sparkle

let updater = Updater()

class Updater {
    private let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    @objc func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    var automaticallyChecksForUpdates: Bool {
        get { return updaterController.updater.automaticallyChecksForUpdates }
        set(v) { updaterController.updater.automaticallyChecksForUpdates = v }
    }
}
