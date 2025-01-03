//
//  URLView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/01/2025.
//

//
//  SnapshotsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import OSLog
import SwiftUI

struct URLView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations

    @State private var selectedconfig: SynchronizeConfiguration?
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var urlverify: URL?
    @State private var urlestimate: URL?

    var body: some View {
        HStack {
            ListofTasksLightView(selecteduuids: $selecteduuids,
                                 profile: rsyncUIdata.profile,
                                 configurations: rsyncUIdata.configurations ?? [])
                .onChange(of: selecteduuids) {
                    if let configurations = rsyncUIdata.configurations {
                        if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                            selectedconfig = configurations[index]
                            let deeplinkurl = DeeplinkURL()
                            if selectedconfig?.offsiteServer.isEmpty == false {
                                // Create verifyremote URL
                                urlverify = deeplinkurl.createURLloadandverify(valueprofile: rsyncUIdata.profile ?? "default", valueid: selectedconfig?.backupID ?? "Synchronize ID")
                            }
                            // Create estimate and synchronize URL
                            urlestimate = deeplinkurl.createURLestimateandsynchronize(valueprofile: rsyncUIdata.profile ?? "default")
                        }
                    }
                }
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text(urlverify?.description ?? "Select a task")
                        .padding()
                    Text(urlestimate?.description ?? "Select a task")
                        .padding()
                }
            }
        }
        .navigationTitle("View URLs")
        .padding()
        .onChange(of: rsyncUIdata.profile) {
            urlverify = nil
            urlestimate = nil
        }
    }
}
