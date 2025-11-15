//
//  NotificationManager.swift
//  Radiola
//
//  Created by Alex Sokolov on 03.11.2025.
//

import Foundation
import UserNotifications

final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    /* ****************************************
     *
     * ****************************************/
    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    /* ****************************************
     *
     * ****************************************/
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let err = error {
                debug("Notification auth error: %@", String(describing: err))
            }

            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    /* ****************************************
     *
     * ****************************************/
    func postNotification(title: String, subtitle: String? = nil, body: String? = nil, userInfo: [AnyHashable: Any]? = nil, identifier: String = UUID().uuidString) {
        let content = UNMutableNotificationContent()
        content.title = title
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        if let body = body {
            content.body = body
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /* ****************************************
     *
     * ****************************************/
    func postNotification(title: String, body: String, userInfo: [AnyHashable: Any]? = nil, identifier: String = UUID().uuidString) {
        let content = UNMutableNotificationContent()
        content.body = title + "\n" + body

        if let userInfo = userInfo {
            content.userInfo = userInfo
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /* ****************************************
     *
     * ****************************************/
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    /* ****************************************
     *
     * ****************************************/
//    func userNotificationCenter(_ center: UNUserNotificationCenter,
//                                didReceive response: UNNotificationResponse,
//                                withCompletionHandler completionHandler: @escaping () -> Void) {
//        let id = response.notification.request.identifier
//        NSLog("User tapped notification id: %@", id)
//        // Можно прочитать response.actionIdentifier или response.notification.request.content.userInfo
//        completionHandler()
//    }
}
