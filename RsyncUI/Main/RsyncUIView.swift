//
//  RsyncUIView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/06/2021.
//

import OSLog
import RsyncProcess
import SwiftUI

struct RsyncUIView: View {
    // Selected profile
    @State private var selectedprofileID: ProfilesnamesRecord.ID?
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
                .onAppear {
                    Task {
                        try await Task.sleep(seconds: 1)
                        start = false
                    }
                }
            } else {
                SidebarMainView(rsyncUIdata: rsyncUIdata,
                                selectedprofileID: $selectedprofileID,
                                errorhandling: errorhandling)
            }
        }
        .padding()
        .task {
            ReadUserConfigurationJSON().readuserconfiguration()
            // Get version of rsync
            rsyncversion.getrsyncversion()
            rsyncUIdata.executetasksinprogress = false
            // Load valid profilenames
            let catalognames = Homepath().getfullpathmacserialcatalogsasstringnames()
            rsyncUIdata.validprofiles = catalognames.map { catalog in
                ProfilesnamesRecord(catalog)
            }
        }
        .task(id: selectedprofileID) {
            var profile: String?
            // Only for external URL
            guard rsyncUIdata.externalurlrequestinprogress == false else {
                rsyncUIdata.externalurlrequestinprogress = false
                return
            }

            if let index = rsyncUIdata.validprofiles.firstIndex(where: { $0.id == selectedprofileID }) {
                rsyncUIdata.profile = rsyncUIdata.validprofiles[index].profilename
                profile = rsyncUIdata.validprofiles[index].profilename
            } else {
                rsyncUIdata.profile = nil
                profile = nil
            }

            rsyncUIdata.profile = profile
            rsyncUIdata.executetasksinprogress = false

            rsyncUIdata.configurations = await ActorReadSynchronizeConfigurationJSON()
                .readjsonfilesynchronizeconfigurations(profile,
                                                       SharedReference.shared.rsyncversion3,
                                                       SharedReference.shared.monitornetworkconnection,
                                                       SharedReference.shared.sshport)
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
