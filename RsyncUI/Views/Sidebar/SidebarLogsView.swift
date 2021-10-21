//
//  SidebarLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/03/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct SidebarLogsView: View {
    @Binding var selectedprofile: String?

    @State private var filterstring: String = ""
    @State private var deleted = false

    var body: some View {
        ZStack {
            TabView {
                LogListAlllogsView(selectedprofile: $selectedprofile, filterstring: $filterstring, deleted: $deleted)
                    .tabItem {
                        Text("All logs")
                    }
                LogsbyConfigurationView(selectedprofile: $selectedprofile, filterstring: $filterstring, deleted: $deleted)
                    .tabItem {
                        Text("By config")
                    }
            }
        }
        .searchable(text: $filterstring)
        .padding()
    }
}
