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
    @State private var otherselectedrsynccommand = OtherRsyncCommand.synchronize_data
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()

    var body: some View {
        VStack {
            ListofTasksLightView(selecteduuids: $selecteduuids,
                                 profile: rsyncUIdata.profile,
                                 configurations: rsyncUIdata.configurations ?? [])
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
            Spacer()

            OtherRsyncCommandsView(config: $selectedconfig, otherselectedrsynccommand: $otherselectedrsynccommand)
        }
        .padding()
    }
}
