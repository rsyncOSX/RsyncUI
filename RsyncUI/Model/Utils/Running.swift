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
    var rsyncUIisrunning: Bool = true // always running
    var rsyncUIscheduleisrunning: Bool = false

    func verifyrsyncui() -> Bool {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: (SharedReference.shared.pathrsyncui ?? "/Applications/") +
            SharedReference.shared.namersyncui) else { return false }
        return true
    }

    private func informscheduletaskisrunning(_ array: [NSRunningApplication]) throws {
        if array.count > 0 {
            throw RunningError.rsyncscheduleisrunning
        }
    }

    init() {
        // Get all running applications
        let workspace = NSWorkspace.shared
        let applications = workspace.runningApplications
        let rsyncschedule = applications.filter { $0.bundleIdentifier == self.rsyncschedule }
        if rsyncschedule.count > 0 {
            rsyncUIscheduleisrunning = true
        } else {
            rsyncUIscheduleisrunning = false
        }
        do {
            try informscheduletaskisrunning(rsyncschedule)
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
    }
}

extension Running: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}

enum RunningError: LocalizedError {
    case rsyncscheduleisrunning

    var errorDescription: String? {
        switch self {
        case .rsyncscheduleisrunning:
            return NSLocalizedString("The menu app is running", comment: "Restore") + "..."
        }
    }
}
