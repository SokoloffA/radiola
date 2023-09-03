//
//  Notifications.swift
//  Radiola
//
//  Created by Alex Sokolov on 02.11.2020.
//  Copyright © 2020 Alex Sokolov. All rights reserved.
//

import Foundation

/* **********************************************
 *
 * **********************************************/
extension Notification.Name {
    // Notifications
    static let StationsChanged = Notification.Name("stationsChanged")

    static let PlayerStatusChanged = Notification.Name("PlayerStatusChanged")
    static let PlayerMetadataChanged = Notification.Name("PlayerMetadataChanged")
    static let PlayerVolumeChanged = Notification.Name("PlayerVolumeChanged")

    static let SettingsChanged = Notification.Name("SettingsChanged")
    static let AudioDeviceChanged = Notification.Name("AudioDeviceChanged")

    static let ErrorOccurred = Notification.Name("ErrorOccurred")
}

/* **********************************************
 *
 * **********************************************/
extension NSObject {
    func errorOccurred(_ message: String) {
        Radiola.errorOccurred(object: self, message: message)
    }
}

/* **********************************************
 *
 * **********************************************/
func errorOccurred(object: Any?, message: String) {
    NotificationCenter.default.post(name: Notification.Name.ErrorOccurred, object: object, userInfo: ["message": message])
}
