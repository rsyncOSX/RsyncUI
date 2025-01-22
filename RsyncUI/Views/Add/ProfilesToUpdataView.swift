//
//  ProfilesToUpdataView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/10/2024.
//

import OSLog
import SwiftUI

struct ProfilesToUpdataView: View {
    let allprofiles: [ProfilesnamesRecord]?
    @State private var configurations: [SynchronizeConfiguration]?

    var body: some View {
        Table(configurations ?? []) {
            TableColumn("Synchronize ID : profilename") { data in
                let split = data.backupID.split(separator: " : ")
                if split.count > 1 {
                    Text(split[0]) + Text(" : ") + Text(split[1]).foregroundColor(.blue)
                } else {
                    Text(data.backupID)
                }
            }
            .width(min: 150, max: 300)
            TableColumn("Task", value: \.task)
                .width(max: 80)
            TableColumn("Days") { data in
                var seconds: Double {
                    if let date = data.dateRun {
                        let lastbackup = date.en_us_date_from_string()
                        return lastbackup.timeIntervalSinceNow * -1
                    } else {
                        return 0
                    }
                }
                let color: Color = markconfig(seconds) == true ? .red : .white
                Text(String(format: "%.2f", seconds / (60 * 60 * 24)))
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                    .foregroundColor(color)
            }
            .width(max: 50)
            TableColumn("Last") { data in
                Text(data.dateRun ?? "")
            }
            .width(max: 120)
        }

        .overlay {
            if let configurations, configurations.count == 0 {
                ContentUnavailableView {
                    Label("All tasks has been synchronized in the past \(SharedReference.shared.marknumberofdayssince) days",
                          systemImage: "play.fill")
                } description: {
                    Text("This is only due to Marknumberofdayssince set in the settings.")
                }
            }
        }

        .task {
            if let allprofiles {
                configurations = await readalltasks(allprofiles)
            }
        }
    }

    private func readalltasks(_ validprofiles: [ProfilesnamesRecord]) async -> [SynchronizeConfiguration] {
        var old: [SynchronizeConfiguration]?
        // Important: we must temporarly disable monitor network connection
        if SharedReference.shared.monitornetworkconnection {
            Logger.process.info("ProfileView: monitornetworkconnection is disabled")
            SharedReference.shared.monitornetworkconnection = false
        }

        let allprofiles = validprofiles.map(\.profilename)

        for i in 0 ..< allprofiles.count {
            let profilename = allprofiles[i]
            let configurations = await ActorReadSynchronizeConfigurationJSON()
                .readjsonfilesynchronizeconfigurations(profilename,
                                                       SharedReference.shared.monitornetworkconnection,
                                                       SharedReference.shared.sshport,
                                                       SharedReference.shared.fileconfigurationsjson)
            let profileold = configurations?.filter { element in
                var seconds: Double {
                    if let date = element.dateRun {
                        let lastbackup = date.en_us_date_from_string()
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
        if old?.count == 0 {
            return []
        } else {
            return old ?? []
        }
    }

    private func markconfig(_ seconds: Double) -> Bool {
        seconds / (60 * 60 * 24) > Double(SharedReference.shared.marknumberofdayssince)
    }
}
