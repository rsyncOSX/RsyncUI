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
    @State private var filterstring: String = ""

    @StateObject private var logrecords = RsyncUIlogrecords()

    var body: some View {
        ZStack {
            TabView {
                LogListAlllogsView(selectedprofile: $selectedprofile, filterstring: $filterstring)
                    .environmentObject(logrecords)
                    .tabItem {
                        Text("All logs")
                    }

                LogsbyConfigurationView(filterstring: $filterstring)
                    .environmentObject(logrecords)
                    .tabItem {
                        Text("By task")
                    }
            }
        }
        .padding()
        .task {
            if selectedprofile == nil {
                selectedprofile = SharedReference.shared.defaultprofile
            }
            // Initialize the Stateobject
            logrecords.readlogsfromstore(profile: selectedprofile, validhiddenIDs: rsyncUIdata.validhiddenIDs)
        }
        .onChange(of: selectedprofile) { _ in
            Task {
                // Update the Stateobject
                if selectedprofile == SharedReference.shared.defaultprofile {
                    let validhiddenIDs = ReadConfigurationJSON(nil).validhiddenIDs
                    logrecords.readlogsfromstore(profile: nil, validhiddenIDs: validhiddenIDs)
                } else {
                    let validhiddenIDs = ReadConfigurationJSON(selectedprofile).validhiddenIDs
                    logrecords.readlogsfromstore(profile: selectedprofile, validhiddenIDs: validhiddenIDs)
                }
            }
        }
    }
}
