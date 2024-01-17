//
//  ListofTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 18/05/2023.
//

import SwiftUI

struct ListofTasksView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var filterstring: String

    var body: some View {
        VStack {
            tabledata
        }
        .searchable(text: $filterstring)
    }

    var tabledata: some View {
        Table((rsyncUIdata.configurations ?? []).filter {
            filterstring.isEmpty ? true : $0.backupID.contains(filterstring)
        }, selection: $selecteduuids) {
            TableColumn("%") { _ in
                Text("")
            }
            .width(max: 50)
            TableColumn("Profile") { _ in
                Text(rsyncUIdata.profile ?? "Default profile")
            }
            .width(min: 50, max: 200)
            TableColumn("Synchronize ID", value: \.backupID)
                .width(min: 50, max: 200)
            TableColumn("Task", value: \.task)
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
            .width(min: 50, max: 80)
            TableColumn("Days") { data in
                var seconds: Double {
                    if let date = data.dateRun {
                        let lastbackup = date.en_us_date_from_string()
                        return lastbackup.timeIntervalSinceNow * -1
                    } else {
                        return 0
                    }
                }
                Text(String(format: "%.2f", seconds / (60 * 60 * 24)))
            }
            .width(max: 50)
            TableColumn("Last") { data in
                Text(data.dateRun ?? "")
            }
            .width(max: 120)
        }
    }
}
