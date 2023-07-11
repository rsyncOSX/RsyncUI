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
    }

    var logrecords: RsyncUIlogrecords {
        return RsyncUIlogrecords(profile: rsyncUIdata.profile, validhiddenIDs: rsyncUIdata.validhiddenIDs)
    }
}
