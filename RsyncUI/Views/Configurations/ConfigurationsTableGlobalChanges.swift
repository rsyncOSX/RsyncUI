//
//  ConfigurationsTableGlobalChanges.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/11/2024.
//

import SwiftUI

struct ConfigurationsTableGlobalChanges: View {
    @Binding var newdata: ObservableGlobalchangeConfigurations
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()

    var body: some View {
        Table(configurations, selection: $selecteduuids) {
            TableColumn("Synchronize ID") { data in
                if selecteduuids.count == 0 {
                    Text(newdata.updatestring(update: newdata.replace_backupID, replace: newdata.occurence_backupID, original: data.backupID))
                }
            }
            .width(min: 50, max: 150)
            TableColumn("Source folder") { data in
                if selecteduuids.count == 0 {
                    Text(newdata.updatestring(update: newdata.replace_localcatalog, replace: newdata.occurence_localcatalog, original: data.localCatalog))
                }
            }
            .width(min: 180, max: 300)
            TableColumn("Destination folder") { data in
                if selecteduuids.count == 0 {
                    Text(newdata.updatestring(update: newdata.replace_remotecatalog, replace: newdata.occurence_remotecatalog, original: data.offsiteCatalog))
                }
            }
            .width(min: 180, max: 300)
            TableColumn("Remote user") { data in
                if selecteduuids.count == 0 {
                    if newdata.occurence_remoteuser.isEmpty == false {
                        Text(newdata.occurence_remoteuser)
                    } else {
                        Text(data.offsiteUsername)
                    }
                } else {
                    if newdata.occurence_remoteuser.isEmpty == false,
                       selecteduuids.contains(data.id)
                    {
                        Text(newdata.occurence_remoteuser)
                    } else {
                        Text(data.offsiteUsername)
                    }
                }
            }
            .width(min: 100, max: 150)
            TableColumn("Remote server") { data in
                if selecteduuids.count == 0 {
                    if newdata.occurence_remoteserver.isEmpty == false {
                        Text(newdata.occurence_remoteserver)
                    } else {
                        Text(data.offsiteServer)
                    }
                } else {
                    if newdata.occurence_remoteserver.isEmpty == false,
                       selecteduuids.contains(data.id)
                    {
                        Text(newdata.occurence_remoteserver)
                    } else {
                        Text(data.offsiteServer)
                    }
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
