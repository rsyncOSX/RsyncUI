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
        }
        .padding()
    }

    var logrecords: RsyncUIlogrecords {
        return RsyncUIlogrecords(profile: rsyncUIdata.profile, validhiddenIDs: rsyncUIdata.validhiddenIDs)
    }
}
