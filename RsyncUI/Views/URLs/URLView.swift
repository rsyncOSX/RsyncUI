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
    @State private var stringverify: String = ""
    @State private var stringestimate: String = ""

    var body: some View {
        VStack(alignment: .leading) {
            ListofTasksLightView(selecteduuids: $selecteduuids,
                                 profile: rsyncUIdata.profile,
                                 configurations: rsyncUIdata.configurations ?? [])
                .onChange(of: selecteduuids) {
                    if let configurations = rsyncUIdata.configurations {
                        if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                            selectedconfig = configurations[index]
                            let deeplinkurl = DeeplinkURL()
                            if selectedconfig?.offsiteServer.isEmpty == false,
                               selectedconfig?.task == SharedReference.shared.synchronize
                            {
                                // Create verifyremote URL
                                urlverify = deeplinkurl.createURLloadandverify(valueprofile: rsyncUIdata.profile ?? "default", valueid: selectedconfig?.backupID ?? "Synchronize ID")
                                stringverify = urlverify?.absoluteString ?? ""
                            } else {
                                stringverify = ""
                            }
                            // Create estimate and synchronize URL
                            urlestimate = deeplinkurl.createURLestimateandsynchronize(valueprofile: rsyncUIdata.profile ?? "default")
                            stringestimate = urlestimate?.absoluteString ?? ""
                        } else {
                            urlverify = nil
                            urlestimate = nil
                            stringverify = ""
                            stringestimate = ""
                        }
                    } else {
                        urlverify = nil
                        urlestimate = nil
                        stringverify = ""
                        stringestimate = ""
                    }
                }
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text("URL for Estimate & Synchronize")
                    EditValue(500, nil, $stringestimate)
                    Text("URL for Verify")
                    EditValue(500, nil, $stringverify)
                }
            }
        }
        .navigationTitle("View URLs")
        .padding()
        .onChange(of: rsyncUIdata.profile) {
            urlverify = nil
            urlestimate = nil
            stringverify = ""
            stringestimate = ""
        }
    }
}
