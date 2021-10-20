//
//  SidebarLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/03/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct SidebarLogsView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedprofile: String?

    @StateObject private var logrecords = RsyncUIlogrecords()
    @State private var filterstring: String = ""
    @State private var deleted = false
    @State private var showloading = true

    var body: some View {
        ZStack {
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

            if showloading { ProgressView() }
        }

        .searchable(text: $filterstring)
        .padding()
        .task {
            if selectedprofile == nil {
                selectedprofile = SharedReference.shared.defaultprofile
            }
            // Initialize the Stateobject
            await logrecords.update(profile: selectedprofile, validhiddenIDs: rsyncUIdata.validhiddenIDs)
            showloading = false
        }
    }
}
