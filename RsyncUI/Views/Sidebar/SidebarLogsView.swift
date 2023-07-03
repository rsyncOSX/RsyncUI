//
//  SidebarLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/03/2021.
//

import SwiftUI

struct SidebarLogsView: View {
    @SwiftUI.Environment(RsyncUIconfigurations.self) private var rsyncUIdata

    @Binding var selectedprofile: String?
    @State private var showloading = true

    var body: some View {
        ZStack {
            TabView {
                LogListAlllogsView(selectedprofile: $selectedprofile)
                    .environment(logrecords)
                    .tabItem {
                        Text("All logs")
                    }

                LogsbyConfigurationView()
                    .environment(logrecords)
                    .tabItem {
                        Text("By task")
                    }
            }
            if showloading { AlertToast(displayMode: .alert, type: .loading) }
        }
        .padding()
        .task {
            if selectedprofile == nil {
                selectedprofile = SharedReference.shared.defaultprofile
            }
            // Initialize the Stateobject
            logrecords.readlogsfromstore(profile: selectedprofile, validhiddenIDs: rsyncUIdata.validhiddenIDs)
            showloading = false
        }
        .onChange(of: selectedprofile) {
            Task {
                showloading = true
                // Update the Stateobject
                if selectedprofile == SharedReference.shared.defaultprofile {
                    let validhiddenIDs = ReadConfigurationJSON(nil).validhiddenIDs
                    logrecords.readlogsfromstore(profile: nil, validhiddenIDs: validhiddenIDs)
                } else {
                    let validhiddenIDs = ReadConfigurationJSON(selectedprofile).validhiddenIDs
                    logrecords.readlogsfromstore(profile: selectedprofile, validhiddenIDs: validhiddenIDs)
                }
                showloading = false
            }
        }
    }

    var logrecords: RsyncUIlogrecords {
        return RsyncUIlogrecords(profile: rsyncUIdata.profile, validhiddenIDs: rsyncUIdata.validhiddenIDs)
    }
}
