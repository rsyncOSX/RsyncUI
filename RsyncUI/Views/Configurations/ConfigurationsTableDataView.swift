//
//  ConfigurationsTableDataView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/04/2024.
//

import SwiftUI

struct ConfigurationsTableDataView: View {
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    let profile: String?
    let configurations: [SynchronizeConfiguration]?

    var body: some View {
        Table(configurations ?? [], selection: $selecteduuids) {
            TableColumn("Profile") { _ in
                Text(profile ?? SharedReference.shared.defaultprofile)
            }
            .width(min: 50, max: 200)
            TableColumn("Synchronize ID") { data in
                if data.backupID.isEmpty == true {
                    Text("Synchronize ID")

                } else {
                    Text(data.backupID)
                }
            }
            .width(min: 50, max: 200)
            TableColumn("Task") { data in
                if data.task == SharedReference.shared.halted {
                    Image(systemName: "stop.fill")
                        .foregroundColor(Color(.red))
                } else {
                    Text(data.task)
                }
            }
            .width(max: 80)
            TableColumn("Local catalog", value: \.localCatalog)
                .width(min: 80, max: 300)
            TableColumn("Remote catalog", value: \.offsiteCatalog)
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
