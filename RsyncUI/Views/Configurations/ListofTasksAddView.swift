//
//  ListofTasksAddView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 25/08/2023.
//

import SwiftUI

struct ListofTasksAddView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<Configuration.ID>

    @State private var confirmdelete: Bool = false

    var body: some View {
        tabledata
    }

    var tabledata: some View {
        Table(rsyncUIdata.configurations ?? [], selection: $selecteduuids) {
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
        .confirmationDialog(
            NSLocalizedString("Delete configuration(s)", comment: "")
                + "?",
            isPresented: $confirmdelete
        ) {
            Button("Delete") {
                delete()
                confirmdelete = false
            }
        }
        .onDeleteCommand {
            confirmdelete = true
        }
    }

    func delete() {
        let deleteconfigurations =
            UpdateConfigurations(profile: rsyncUIdata.profile,
                                 configurations: rsyncUIdata.getallconfigurations())
        deleteconfigurations.deleteconfigurations(uuids: selecteduuids)
        selecteduuids.removeAll()
        rsyncUIdata.configurations = deleteconfigurations.configurations
        rsyncUIdata.resetandupdatevalidhiddenIDS()
    }
}
