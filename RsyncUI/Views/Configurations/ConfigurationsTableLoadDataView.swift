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
                if data.parameter4?.isEmpty == false {
                    if data.backupID.isEmpty == true {
                        Text("Synchronize ID")
                            .foregroundColor(.red)
                    } else {
                        Text(data.backupID)
                            .foregroundColor(.red)
                    }
                } else {
                    if data.backupID.isEmpty == true {
                        Text("Synchronize ID")
                    } else {
                        Text(data.backupID)
                    }
                }
            }
            .width(min: 90, max: 200)

            TableColumn("Action") { data in
                if data.task == SharedReference.shared.halted {
                    Image(systemName: "stop.fill")
                        .foregroundColor(Color(.red))
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
        .task(id: uuidprofile) {
            var profile = ""
            let record = rsyncUIdata.validprofiles.filter { $0.id == uuidprofile }
            guard record.count > 0 else { return }
            profile = record[0].profilename
            configurations = await ActorReadSynchronizeConfigurationJSON()
                .readjsonfilesynchronizeconfigurations(profile,
                                                       SharedReference.shared.rsyncversion3)
        }
        .onChange(of: uuidprofile) {
            Task {
                configurations = []
                var profile = ""
                let record = rsyncUIdata.validprofiles.filter { $0.id == uuidprofile }
                guard record.count > 0 else { return }
                profile = record[0].profilename
                configurations = await ActorReadSynchronizeConfigurationJSON()
                    .readjsonfilesynchronizeconfigurations(profile,
                                                           SharedReference.shared.rsyncversion3)
            }
        }
    }
}
