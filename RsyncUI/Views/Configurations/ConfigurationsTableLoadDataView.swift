//
//  ConfigurationsTableLoadDataView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/12/2025.
//

import SwiftUI

struct ConfigurationsTableLoadDataView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var uuidprofile: ProfilesnamesRecord.ID?

    @State private var configurations: [SynchronizeConfiguration]?

    var body: some View {
        Table(configurations ?? []) {
            TableColumn("Synchronize ID") { data in
                HStack(spacing: 4) {
                    ConfigurationNameLabel(configuration: data)
                        .layoutPriority(1)

                    ConfigurationTaskBadge(task: data.task, hidesSynchronize: true)
                }
            }
            .width(min: 130, ideal: 160, max: 220)

            TableColumn("Source", value: \.localCatalog)
                .width(min: 60, max: 300)
            TableColumn("Destination", value: \.offsiteCatalog)
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
        .task(id: uuidprofile) {
            configurations = []
            let record = rsyncUIdata.validprofiles.filter { $0.id == uuidprofile }
            guard record.count > 0 else { return }
            let profile = record[0].profilename
            configurations = await ReadSynchronizeConfigurationJSON()
                .readjsonfilesynchronizeconfigurations(profile,
                                                       SharedReference.shared.rsyncversion3)
        }
    }
}
