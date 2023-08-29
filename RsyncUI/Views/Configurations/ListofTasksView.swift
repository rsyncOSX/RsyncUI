//
//  ListofTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 18/05/2023.
//

import SwiftUI

struct ListofTasksView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var filterstring: String

    var body: some View {
        VStack {
            tabledata
        }
        .searchable(text: $filterstring)
    }

    var tabledata: some View {
        Table(configurationssorted, selection: $selecteduuids) {
            TableColumn("%") { _ in
                Text("")
            }
            .width(max: 50)
            TableColumn("Profile") { data in
                if markconfig(data) {
                    Text(data.profile ?? "Default profile")
                        .foregroundColor(.red)
                } else {
                    Text(data.profile ?? "Default profile")
                }
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
                if markconfig(data) {
                    Text(data.dayssincelastbackup ?? "")
                        .foregroundColor(.red)
                } else {
                    Text(data.dayssincelastbackup ?? "")
                }
            }
            .width(max: 50)
            TableColumn("Last") { data in
                if markconfig(data) {
                    Text(data.dateRun ?? "")
                        .foregroundColor(.red)
                } else {
                    Text(data.dateRun ?? "")
                }
            }
            .width(max: 120)
        }
    }

    var configurationssorted: [Configuration] {
        if filterstring.isEmpty {
            return rsyncUIdata.configurations ?? []
        } else {
            return rsyncUIdata.filterconfigurations(filterstring) ?? []
        }
    }

    func markconfig(_ config: Configuration?) -> Bool {
        if config?.dateRun != nil {
            if let secondssince = config?.lastruninseconds {
                if secondssince / (60 * 60 * 24) > Double(SharedReference.shared.marknumberofdayssince) {
                    return true
                }
            }
        }
        return false
    }
}
