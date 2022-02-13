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

    func isrsyncshedulerunning() -> Bool {
        return rsyncUIscheduleisrunning
    }

    func informifisrsyncshedulerunning() -> Bool {
        // Get all running applications
        let workspace = NSWorkspace.shared
        let applications = workspace.runningApplications
        let rsyncschedule = applications.filter { $0.bundleIdentifier == self.rsyncschedule }
        do {
            try informscheduletaskisrunning(rsyncschedule)
            return false
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
        return true
    }

    private func informscheduletaskisrunning(_ array: [NSRunningApplication]) throws {
        if array.count > 0 {
            throw RunningError.rsyncscheduleisrunning
        }
    }

    @discardableResult
    init() {
        // Get all running applications
        let workspace = NSWorkspace.shared
        let applications = workspace.runningApplications
        let rsyncschedule = applications.filter { $0.bundleIdentifier == self.rsyncschedule }
        if rsyncschedule.count > 0 {
            rsyncUIscheduleisrunning = true
            // SharedReference.shared.menuappisrunning = true
        } else {
            rsyncUIscheduleisrunning = false
            // SharedReference.shared.menuappisrunning = false
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
            return "The menu app is running"
        }
    }
}
