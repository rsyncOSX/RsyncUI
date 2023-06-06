//
//  SidebarLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/03/2021.
//

import SwiftUI

struct SidebarLogsView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedprofile: String?

    @StateObject private var logrecords = RsyncUIlogrecords()
    @State private var showloading = true

    @State private var focusselectlog: Bool = false

    var body: some View {
        ZStack {
            TabView {
                LogListAlllogsView(selectedprofile: $selectedprofile,
                                   focusselectlog: $focusselectlog)
                    .environmentObject(logrecords)
                    .tabItem {
                        Text("All logs")
                    }

                LogsbyConfigurationView(selectedprofile: selectedprofile)
                    .environmentObject(logrecords)
                    .tabItem {
                        Text("By task")
                    }
            }
            if showloading { ProgressView() }
        }
        .padding()
        .task {
            if selectedprofile == nil {
                selectedprofile = SharedReference.shared.defaultprofile
            }
            // Initialize the Stateobject
            logrecords.readlogrecords(profile: selectedprofile, validhiddenIDs: rsyncUIdata.validhiddenIDs)
            showloading = false
        }
        .onChange(of: selectedprofile) { _ in
            Task {
                showloading = true
                // Update the Stateobject
                if selectedprofile == SharedReference.shared.defaultprofile {
                    let validhiddenIDs = ReadConfigurationJSON(nil).validhiddenIDs
                    logrecords.readlogrecords(profile: nil, validhiddenIDs: validhiddenIDs)
                } else {
                    let validhiddenIDs = ReadConfigurationJSON(selectedprofile).validhiddenIDs
                    logrecords.readlogrecords(profile: selectedprofile, validhiddenIDs: validhiddenIDs)
                }
                showloading = false
            }
        }
        .focusedSceneValue(\.selectlog, $focusselectlog)
    }
}
