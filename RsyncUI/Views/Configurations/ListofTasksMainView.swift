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
    @Binding var doubleclick: Bool
    // Progress of synchronization
    @Binding var progress: Double

    @State private var confirmdelete: Bool = false
    // Filterstring
    @State private var filterstring: String = ""

    let progressdetails: ProgressDetails
    let max: Double

    var body: some View {
        ConfigurationsTableDataMainView(rsyncUIdata: rsyncUIdata,
                                        selecteduuids: $selecteduuids,
                                        filterstring: $filterstring,
                                        progress: $progress,
                                        progressdetails: progressdetails,
                                        max: max)
            .overlay {
                if (rsyncUIdata.configurations ?? []).filter(
                    { filterstring.isEmpty ? true : $0.backupID.contains(filterstring) }).isEmpty
                {
                    ContentUnavailableView {
                        Label("There are no tasks by this Synchronize ID", systemImage: "doc.richtext.fill")
                    } description: {
                        Text("Try to search for other filter in Synchronize ID or \n If new user, add Tasks")
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
            } primaryAction: { _ in
                // Only allow double click if one task is selected
                guard selecteduuids.count == 1 else { return }
                doubleclick = true
            }
            .onDeleteCommand {
                confirmdelete = true
            }
            .onChange(of: filterstring) {
                Task {
                    try await Task.sleep(seconds: 2)
                    if let filteredconfigurations = rsyncUIdata.configurations?.filter({ filterstring.isEmpty ? true : $0.backupID.contains(filterstring) }) {
                        guard filterstring.isEmpty == false else {
                            // selecteduuids.removeAll()
                            return
                        }

                        _ = filteredconfigurations.map { configuration in
                            selecteduuids.insert(configuration.id)
                        }
                    }
                }
            }
    }

    func delete() {
        if let configurations = rsyncUIdata.configurations {
            let deleteconfigurations =
                UpdateConfigurations(profile: rsyncUIdata.profile,
                                     configurations: configurations)
            deleteconfigurations.deleteconfigurations(selecteduuids)
            selecteduuids.removeAll()
            rsyncUIdata.configurations = deleteconfigurations.configurations
        }
    }
}
