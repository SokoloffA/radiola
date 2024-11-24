//
//  Notifications.swift
//  Radiola
//
//  Created by Alex Sokolov on 02.11.2020.
//  Copyright © 2020 Alex Sokolov. All rights reserved.
//

import Foundation

/* **********************************************
 * Notifications
 * **********************************************/
extension Notification.Name {
    static let PlayerStatusChanged = Notification.Name("PlayerStatusChanged")
    static let PlayerMetadataChanged = Notification.Name("PlayerMetadataChanged")
    static let PlayerVolumeChanged = Notification.Name("PlayerVolumeChanged")

    static let SettingsChanged = Notification.Name("SettingsChanged")
    static let AudioDeviceChanged = Notification.Name("AudioDeviceChanged")
}
