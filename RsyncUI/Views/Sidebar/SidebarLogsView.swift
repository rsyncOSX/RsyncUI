//
//  SidebarLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/03/2021.
//

import SwiftUI

struct SidebarLogsView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @Binding var reload: Bool
    @Binding var selectedprofile: String?

    var body: some View {
        TabView {
            LogListAlllogsView(reload: $reload, selectedprofile: $selectedprofile)
                .tabItem {
                    Text("All logs")
                }
            LogsbyConfigurationView(reload: $reload, selectedprofile: $selectedprofile)
                .tabItem {
                    Text("By config")
                }
        }
        .padding()
    }
}
