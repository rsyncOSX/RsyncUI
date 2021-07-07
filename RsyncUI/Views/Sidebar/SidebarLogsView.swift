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

    @State private var filterstring: String = ""

    var body: some View {
        TabView {
            LogListAlllogsView(reload: $reload, selectedprofile: $selectedprofile, filterstring: $filterstring)
                .tabItem {
                    Text("All logs")
                }
            LogsbyConfigurationView(reload: $reload, selectedprofile: $selectedprofile, filterstring: $filterstring)
                .tabItem {
                    Text("By config")
                }
        }
        .searchable(text: $filterstring)
        .padding()
    }
}
