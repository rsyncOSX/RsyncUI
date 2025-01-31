//
//  ArgumentsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 16/09/2024.
//

import SwiftUI

struct ArgumentsView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations

    @State private var selectedconfig: SynchronizeConfiguration?
    @State private var otherselectedrsynccommand = OtherRsyncCommand.list_remote_files
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var filterstring: String = ""

    var body: some View {
        VStack {
            ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                        filterstring: $filterstring,
                                        profile: rsyncUIdata.profile,
                                        configurations: rsyncUIdata.configurations)
                .frame(maxWidth: .infinity)
                .onChange(of: selecteduuids) {
                    if let configurations = rsyncUIdata.configurations {
                        if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                            selectedconfig = configurations[index]
                        } else {
                            selectedconfig = nil
                        }
                    }
                }
                .onChange(of: rsyncUIdata.profile) {
                    selecteduuids.removeAll()
                    selectedconfig = nil
                }

            VStack(alignment: .leading) {
                Text("Select a task")

                OtherRsyncCommandsView(config: $selectedconfig, otherselectedrsynccommand: $otherselectedrsynccommand)
                    .disabled(selectedconfig == nil)
            }
        }
        .padding()
    }
}
