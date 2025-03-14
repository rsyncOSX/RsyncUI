//
//  ConfigurationsTableGlobalChanges.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/11/2024.
//

import SwiftUI

struct ConfigurationsTableGlobalChanges: View {
    @Binding var newdata: ObservableGlobalchangeConfigurations

    var body: some View {
        Table(configurations) {
            TableColumn("Synchronize ID") { data in
                if newdata.occurence_backupID.isEmpty == false, newdata.occurence_backupID.contains("$") {
                    Text(newdata.splitinput(input: newdata.occurence_backupID, original: data.backupID))
                } else {
                    Text(data.backupID)
                }
            }
            .width(min: 50, max: 150)
            TableColumn("Local catalog") { data in
                if newdata.occurence_localcatalog.isEmpty == false, newdata.occurence_localcatalog.contains("$") {
                    Text(newdata.splitinput(input: newdata.occurence_localcatalog, original: data.localCatalog))
                } else {
                    Text(data.localCatalog)
                }
            }
            .width(min: 180, max: 300)
            TableColumn("Remote catalog") { data in
                if newdata.occurence_remotecatalog.isEmpty == false, newdata.occurence_remotecatalog.contains("$") {
                    Text(newdata.splitinput(input: newdata.occurence_remotecatalog, original: data.offsiteCatalog))
                } else {
                    Text(data.offsiteCatalog)
                }
            }
            .width(min: 180, max: 300)
            TableColumn("Remote user") { data in
                if newdata.occurence_remoteuser.isEmpty == false {
                    Text(newdata.occurence_remoteuser)
                } else {
                    Text(data.offsiteUsername)
                }
            }
            .width(min: 100, max: 150)
            TableColumn("Remote server") { data in
                if newdata.occurence_remoteserver.isEmpty == false {
                    Text(newdata.occurence_remoteserver)
                } else {
                    Text(data.offsiteServer)
                }
            }
            .width(min: 100, max: 150)
        }
        .overlay {
            if configurations.isEmpty {
                ContentUnavailableView {
                    Label("Most likely, you try to update snapshot tasks, not allowed",
                          systemImage: "doc.richtext.fill")
                } description: {
                    Text("Or there are no tasks to update")
                }
            }
        }
        .padding()
    }

    var configurations: [SynchronizeConfiguration] {
        if let configurations = newdata.globalchangedconfigurations {
            configurations
        } else {
            []
        }
    }
}
