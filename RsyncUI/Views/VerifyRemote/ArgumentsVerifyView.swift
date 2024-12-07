//
//  ArgumentsVerifyView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/12/2024.
//

import SwiftUI

struct ArgumentsVerifyView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations

    @State private var selectedconfig: SynchronizeConfiguration?
    @State private var otherselectedrsynccommand = OtherRsyncCommand.push_local
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()

    var body: some View {
        VStack {
            ListofTasksLightView(selecteduuids: $selecteduuids,
                                 profile: rsyncUIdata.profile,
                                 configurations: rsyncUIdata.configurations?.filter({ $0.offsiteServer.isEmpty == false }) ?? [])
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
                .disabled(selectedconfig == nil)
        }
        .padding()
    }
}
