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
    @State private var filterstring: String = ""
    @State private var deleted = false

    var body: some View {
        TabView {
            LogListAlllogsView(selectedprofile: $selectedprofile, filterstring: $filterstring, deleted: $deleted)
                .environmentObject(logrecords)
                .tabItem {
                    Text("All logs")
                }
            LogsbyConfigurationView(selectedprofile: $selectedprofile, filterstring: $filterstring, deleted: $deleted)
                .environmentObject(logrecords)
                .tabItem {
                    Text("By config")
                }
        }
        .searchable(text: $filterstring)
        .padding()
        .onAppear(perform: {
            if selectedprofile == nil {
                selectedprofile = SharedReference.shared.defaultprofile
            }
            // Initialize the Stateobject
            logrecords.update(profile: selectedprofile, validhiddenIDs: rsyncUIdata.validhiddenIDs)
        })
    }
}
