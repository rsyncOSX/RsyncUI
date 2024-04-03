//
//  ListofTasksMainView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import SwiftUI

struct ListofTasksMainView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var filterstring: String
    @Binding var doubleclick: Bool
    // Progress of synchronization
    @Binding var progress: Double

    @State private var confirmdelete: Bool = false

    let executeprogressdetails: ExecuteProgressDetails
    let max: Double

    var body: some View {
        ConfigurationsTableDataMainView(selecteduuids: $selecteduuids,
                                        filterstring: $filterstring,
                                        progress: $progress,
                                        profile: rsyncUIdata.profile,
                                        configurations: rsyncUIdata.configurations ?? [],
                                        executeprogressdetails: executeprogressdetails,
                                        max: max)
            .overlay {
                if (rsyncUIdata.configurations ?? []).filter(
                    { filterstring.isEmpty ? true : $0.backupID.contains(filterstring) }).isEmpty
                {
                    ContentUnavailableView {
                        Label("There are no tasks by this Synchronize ID", systemImage: "doc.richtext.fill")
                    } description: {
                        Text("Try to search for other filter in Synchronize ID or \n If new user, add Tasks.")
                    }
                }
            }
            .searchable(text: $filterstring)
            .confirmationDialog(
                Text("Delete ^[\(selecteduuids.count) configuration](inflect: true)"),
                isPresented: $confirmdelete
            ) {
                Button("Delete") {
                    delete()
                    confirmdelete = false
                }
            }
            .contextMenu(forSelectionType: SynchronizeConfiguration.ID.self) { _ in
                // ...
            } primaryAction: { _ in
                doubleclick = true
            }
            .onDeleteCommand {
                confirmdelete = true
            }
    }

    func delete() {
        if let configurations = rsyncUIdata.configurations {
            let deleteconfigurations =
                UpdateConfigurations(profile: rsyncUIdata.profile,
                                     configurations: configurations)
            deleteconfigurations.deleteconfigurations(uuids: selecteduuids)
            selecteduuids.removeAll()
            rsyncUIdata.configurations = deleteconfigurations.configurations
        }
    }

    func markconfig(_ seconds: Double) -> Bool {
        return seconds / (60 * 60 * 24) > Double(SharedReference.shared.marknumberofdayssince)
    }
}
