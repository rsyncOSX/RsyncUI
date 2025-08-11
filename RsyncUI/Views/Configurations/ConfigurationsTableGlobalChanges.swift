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
        Table(configurations, selection: $newdata.selecteduuids) {
            TableColumn("Synchronize ID") { data in
                if newdata.selecteduuids.contains(data.id) {
                    Text(newdata.updatestring(update: newdata.replace_backupID,
                                              replace: newdata.occurence_backupID,
                                              original: data.backupID))
                    .foregroundColor(.red)
                } else if newdata.selecteduuids.isEmpty {
                    Text(newdata.updatestring(update: newdata.replace_backupID,
                                              replace: newdata.occurence_backupID,
                                              original: data.backupID))
                } else {
                    Text(data.backupID)
                }
                
            }
            .width(min: 50, max: 150)
            TableColumn("Source folder") { data in
                if newdata.selecteduuids.contains(data.id) {
                    Text(newdata.updatestring(update: newdata.replace_localcatalog,
                                              replace: newdata.occurence_localcatalog,
                                              original: data.localCatalog))
                    .foregroundColor(.red)
                } else if newdata.selecteduuids.isEmpty {
                    Text(newdata.updatestring(update: newdata.replace_localcatalog,
                                              replace: newdata.occurence_localcatalog,
                                              original: data.localCatalog))
                } else {
                    Text(data.localCatalog)
                }
            }
            .width(min: 180, max: 300)
            TableColumn("Destination folder") { data in
                if newdata.selecteduuids.contains(data.id) {
                    Text(newdata.updatestring(update: newdata.replace_remotecatalog,
                                              replace: newdata.occurence_remotecatalog,
                                              original: data.offsiteCatalog))
                    .foregroundColor(.red)
                } else if newdata.selecteduuids.isEmpty {
                    Text(newdata.updatestring(update: newdata.replace_remotecatalog,
                                              replace: newdata.occurence_remotecatalog,
                                              original: data.offsiteCatalog))
                } else {
                    Text(data.offsiteCatalog)
                }
            }
            .width(min: 180, max: 300)
            TableColumn("Remote user") { data in
                if newdata.occurence_remoteuser.isEmpty == false,
                   newdata.selecteduuids.contains(data.id)
                {
                    Text(newdata.occurence_remoteuser)
                        .foregroundColor(.red)
                } else {
                    Text(data.offsiteUsername)
                }
            }
            .width(min: 100, max: 150)
            TableColumn("Remote server") { data in
                if newdata.occurence_remoteserver.isEmpty == false,
                   newdata.selecteduuids.contains(data.id)
                {
                    Text(newdata.occurence_remoteserver)
                        .foregroundColor(.red)
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
