//
//  ConfigurationsTableDataView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/04/2024.
//

import SwiftUI

struct ConfigurationsTableDataView: View {
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    let configurations: [SynchronizeConfiguration]?

    var body: some View {
        Table(configurations ?? [], selection: $selecteduuids) {
            TableColumn("Synchronize ID") { data in
                HStack(spacing: 4) {
                    if data.parameter4?.isEmpty == false {
                        if data.backupID.isEmpty == true {
                            Text("No ID set")
                                .foregroundStyle(.red)
                        } else {
                            Text(data.backupID)
                                .foregroundStyle(.red)
                        }
                    } else {
                        if data.backupID.isEmpty == true {
                            Text("No ID set")
                                .foregroundStyle(.blue)
                        } else {
                            Text(data.backupID)
                                .foregroundStyle(.blue)
                        }
                    }

                    ConfigurationTaskBadge(task: data.task)
                }
            }
            .width(min: 90, max: 200)

            TableColumn("Source", value: \.localCatalog)
                .width(min: 80, max: 300)
            TableColumn("Destination", value: \.offsiteCatalog)
                .width(min: 80, max: 300)
            TableColumn("Server") { data in
                if data.offsiteServer.count > 0 {
                    Text(data.offsiteServer)
                } else {
                    Text("localhost")
                }
            }
            .width(min: 50, max: 90)
        }
    }
}

@MainActor
extension SynchronizeConfiguration {
    /// Nil if the task is never run, a new task has an empty date
    var lastRun: Date? {
        guard let dateRun, !dateRun.isEmpty else { return nil }
        return dateRun.en_date_from_string()
    }
}
