//
//  ReadAllTasks.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/02/2025.
//

import Foundation
import OSLog

@MainActor
struct ReadAllTasks {
    func readallmarkedtasks(_ validprofiles: [ProfilesnamesRecord]) async -> [SynchronizeConfiguration] {
        var old: [SynchronizeConfiguration]?
        // Important: we must temporarly disable monitor network connection
        if SharedReference.shared.monitornetworkconnection {
            Logger.process.info("ReadAllTasks: monitornetworkconnection is disabled")
            SharedReference.shared.monitornetworkconnection = false
        }

        let allprofiles = validprofiles.map(\.profilename)
        Logger.process.debugtthreadonly("ReadAllTasks: readallmarkedtasks()")
        let monitornetworkconnection = SharedReference.shared.monitornetworkconnection
        let sshport = SharedReference.shared.sshport
        let rsyncversion3 = SharedReference.shared.rsyncversion3

        for i in 0 ..< allprofiles.count {
            let profilename = allprofiles[i]

            async let configurations = ActorReadSynchronizeConfigurationJSON()
                .readjsonfilesynchronizeconfigurations(profilename,
                                                       rsyncversion3,
                                                       monitornetworkconnection,
                                                       sshport)

            let profileold = await configurations?.filter { element in
                var seconds: Double {
                    if let date = element.dateRun {
                        let lastbackup = date.en_date_from_string()
                        return lastbackup.timeIntervalSinceNow * -1
                    } else {
                        return 0
                    }
                }
                return markconfig(seconds) == true
            }

            if old == nil, let profileold {
                old = profileold.map { element in
                    var newelement = element
                    if newelement.backupID.isEmpty {
                        newelement.backupID = "Synchronize ID"
                    }
                    newelement.backupID += " : " + profilename
                    return newelement
                }
            } else {
                if let profileold {
                    let profileold = profileold.map { element in
                        var newelement = element
                        if newelement.backupID.isEmpty {
                            newelement.backupID = "Synchronize ID"
                        }
                        newelement.backupID += " : " + profilename
                        return newelement
                    }
                    old?.append(contentsOf: profileold)
                }
            }
        }

        Logger.process.info("ReadAllTasks: readallmarkedtasks() COMPLETED async CALLs")

        if old?.count == 0 {
            return []
        } else {
            return old ?? []
        }
    }

    private func markconfig(_ seconds: Double) -> Bool {
        seconds / (60 * 60 * 24) > Double(SharedReference.shared.marknumberofdayssince)
    }

    // Put profilename in Backup ID
    func readalltasks(_ validprofiles: [ProfilesnamesRecord]) async -> [SynchronizeConfiguration] {
        var allconfigurations: [SynchronizeConfiguration] = []
        // Important: we must temporarly disable monitor network connection
        if SharedReference.shared.monitornetworkconnection {
            Logger.process.info("ReadAllTasks: monitornetworkconnection is disabled")
            SharedReference.shared.monitornetworkconnection = false
        }

        let allprofiles = validprofiles.map(\.profilename)

        Logger.process.info("ReadAllTasks: readalltasks() START of async CALLs")

        for i in 0 ..< allprofiles.count {
            let profilename = allprofiles[i]

            // Logger.process.info("ReadAllTasks: readalltasks() LET ASYNC")

            let configurations = await ActorReadSynchronizeConfigurationJSON()
                .readjsonfilesynchronizeconfigurations(profilename,
                                                       SharedReference.shared.rsyncversion3,
                                                       SharedReference.shared.monitornetworkconnection,
                                                       SharedReference.shared.sshport)

            let adjustedconfigurations = configurations?.map { element in
                var newelement = element
                newelement.backupID = profilename
                return newelement
            }

            if let adjustedconfigurations {
                allconfigurations.append(contentsOf: adjustedconfigurations)
            }
        }

        Logger.process.info("ReadAllTasks: readalltasks() COMPLETED async CALLs")

        return allconfigurations
    }
}
