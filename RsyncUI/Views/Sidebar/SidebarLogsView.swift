//
//  SidebarLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/03/2021.
//

import SwiftUI

struct SidebarLogsView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @State private var filterstring: String = ""

    var body: some View {
        ZStack {
            TabView {
                LogsbyConfigurationView(filterstring: $filterstring,
                                        logrecords: logrecords)
                    .tabItem {
                        Text("By task")
                    }

                LogListAlllogsView(filterstring: $filterstring,
                                   logrecords: logrecords)
                    .tabItem {
                        Text("All logs")
                    }
            }
        }
        .padding()
    }

    var logrecords: RsyncUIlogrecords {
        return RsyncUIlogrecords(profile: rsyncUIdata.profile, validhiddenIDs: rsyncUIdata.validhiddenIDs)
    }
}
