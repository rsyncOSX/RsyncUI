//
//  Running.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 07.02.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

import AppKit
import Foundation

final class Running {
    let rsyncui = "no.blogspot.RsyncUI"
    let rsyncschedule = "no.blogspot.RsyncSchedule"
    var rsyncUIisrunning: Bool = false
    var rsyncUIscheduleisrunning: Bool = false

    func verifyrsyncui() -> Bool {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: (SharedReference.shared.pathrsyncui ?? "/Applications/") +
            SharedReference.shared.namersyncui) else { return false }
        return true
    }

    init() {
        // Get all running applications
        let workspace = NSWorkspace.shared
        let applications = workspace.runningApplications
        let rsyncui = applications.filter { $0.bundleIdentifier == self.rsyncui }
        let rsyncschedule = applications.filter { $0.bundleIdentifier == self.rsyncschedule }
        if rsyncui.count > 0 {
            rsyncUIisrunning = true
        } else {
            rsyncUIisrunning = false
        }
        if rsyncschedule.count > 0 {
            rsyncUIscheduleisrunning = true
        } else {
            rsyncUIscheduleisrunning = false
        }
    }
}
