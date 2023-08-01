//
//  SidebarLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/03/2021.
//

import SwiftUI

struct SidebarLogsView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @State private var filterstring: String = ""
    @State private var showloading = true

    var body: some View {
        ZStack {
            TabView {
                LogListAlllogsView(filterstring: $filterstring,
                                   logrecords: logrecords)
                    .tabItem {
                        Text("All logs")
                    }

                LogsbyConfigurationView(filterstring: $filterstring,
                                        logrecords: logrecords)
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
