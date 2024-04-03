//
//  ListofTasksAddView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 25/08/2023.
//

import SwiftUI

struct ListofTasksAddView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @State private var confirmdelete: Bool = false
    @State private var filterstring: String = ""

    var body: some View {
        ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                    filterstring: $filterstring,
                                    profile: rsyncUIdata.profile,
                                    configurations: rsyncUIdata.configurations ?? [])
            .confirmationDialog(
                Text("Delete ^[\(selecteduuids.count) configuration](inflect: true)"),
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
        if let configurations = rsyncUIdata.configurations {
            let deleteconfigurations =
                UpdateConfigurations(profile: rsyncUIdata.profile,
                                     configurations: configurations)
            deleteconfigurations.deleteconfigurations(uuids: selecteduuids)
            selecteduuids.removeAll()
            rsyncUIdata.configurations = deleteconfigurations.configurations
        }
    }
}
