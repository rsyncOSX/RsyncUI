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

    var body: some View {
        ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                    configurations: rsyncUIdata.configurations)
            .confirmationDialog(selecteduuids.count == 1 ? "Delete 1 configuration" :
                "Delete \(selecteduuids.count) configurations",
                isPresented: $confirmdelete)
            {
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
            deleteconfigurations.deleteconfigurations(selecteduuids)
            selecteduuids.removeAll()
            rsyncUIdata.configurations = deleteconfigurations.configurations
        }
    }
}
