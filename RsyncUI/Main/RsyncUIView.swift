//
//  RsyncUIView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/06/2021.
//

import OSLog
import SwiftUI

struct RsyncUIView: View {
    @State private var selectedprofile: String? = SharedConstants().defaultprofile
    // Set version of rsync to use
    @State private var rsyncversion = Rsyncversion()
    @State private var start: Bool = true

    @State private var rsyncUIdata = RsyncUIconfigurations()

    var body: some View {
        VStack {
            if start {
                VStack {
                    Text("RsyncUI a GUI for rsync")
                        .font(.largeTitle)
                    Text("https://rsyncui.netlify.app")
                        .font(.title2)
                }
                .onAppear(perform: {
                    Task {
                        try await Task.sleep(seconds: 1)
                        start = false
                    }

                })
            } else {
                SidebarMainView(rsyncUIdata: rsyncUIdata,
                                selectedprofile: $selectedprofile,
                                errorhandling: errorhandling)
            }
        }
        .padding()
        .task {
            ReadUserConfigurationJSON().readuserconfiguration()
            // Get version of rsync
            rsyncversion.getrsyncversion()
            rsyncUIdata.profile = selectedprofile
            rsyncUIdata.configurations = await ActorReadSynchronizeConfigurationJSON()
                .readjsonfilesynchronizeconfigurations(selectedprofile,
                                                       SharedReference.shared.monitornetworkconnection,
                                                       SharedReference.shared.sshport)
            let catalognames = Homepath().getfullpathmacserialcatalogsasstringnames()
            rsyncUIdata.validprofiles = catalognames.map { catalog in
                ProfilesnamesRecord(catalog)
            }
        }
        .onChange(of: selectedprofile) {
            // Only for external URL
            guard rsyncUIdata.externalurlrequestinprogress == false else {
                Logger.process.info("RsyncUIView: external URL loaded")
                rsyncUIdata.externalurlrequestinprogress = false
                return
            }
            Task {
                rsyncUIdata.profile = selectedprofile
                rsyncUIdata.configurations = await ActorReadSynchronizeConfigurationJSON()
                    .readjsonfilesynchronizeconfigurations(selectedprofile,
                                                           SharedReference.shared.monitornetworkconnection,
                                                           SharedReference.shared.sshport)
            }
        }
    }

    var errorhandling: AlertError {
        SharedReference.shared.errorobject = AlertError()
        return SharedReference.shared.errorobject ?? AlertError()
    }
}

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
