//
//  Notifications.swift
//  Radiola
//
//  Created by Alex Sokolov on 02.11.2020.
//  Copyright © 2020 Alex Sokolov. All rights reserved.
//

import Foundation

extension Notification.Name {
    // Notifications
    static let StationsChanged = Notification.Name("stationsChanged")

    static let PlayerStatusChanged   = Notification.Name("PlayerStatusChanged")
    static let PlayerMetadataChanged = Notification.Name("PlayerMetadataChanged")
 
}
