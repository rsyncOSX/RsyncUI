//
//  Notifications.swift
//  RsyncOSXsched
//
//  Created by Thomas Evensen on 21.02.2018.
//  Copyright © 2018 Maxim. All rights reserved.
//

import Foundation
import UserNotifications

struct Notifications {
    func showNotification(_ message: String) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "A notifiction from RsyncUI"
        content.subtitle = message
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request)
    }
}
