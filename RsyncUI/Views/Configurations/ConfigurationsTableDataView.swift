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
            }
            .width(min: 90, max: 200)

            TableColumn("Action") { data in
                if data.task == SharedReference.shared.halted {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(Color(.red))
                } else {
                    Text(data.task)
                }
            }
            .width(max: 80)
            TableColumn("Source folder", value: \.localCatalog)
                .width(min: 80, max: 300)
            TableColumn("Destination folder", value: \.offsiteCatalog)
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
