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
                    ConfigurationNameLabel(configuration: data)
                        .layoutPriority(1)

                    ConfigurationTaskBadge(task: data.task, hidesSynchronize: true)
                }
            }
            .width(min: 130, ideal: 160, max: 220)

            TableColumn("Source", value: \.displaySourcePath)
                .width(min: 60, max: 300)
            TableColumn("Destination", value: \.displayDestinationPath)
                .width(min: 60, max: 300)
            TableColumn("Server") { data in
                if data.offsiteServer.count > 0 {
                    Text(data.offsiteServer)
                } else {
                    Text("localhost")
                }
            }
            .width(min: 75, ideal: 85, max: 110)
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

    var displaysRemoteSource: Bool {
        task == SharedReference.shared.syncremote ||
            (task == SharedReference.shared.halted && halted == 2)
    }

    var displaySourcePath: String {
        displaysRemoteSource ? offsiteCatalog : localCatalog
    }

    var displayDestinationPath: String {
        displaysRemoteSource ? localCatalog : offsiteCatalog
    }
}
