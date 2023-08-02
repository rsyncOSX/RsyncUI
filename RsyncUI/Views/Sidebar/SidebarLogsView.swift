//
//  SidebarLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/03/2021.
//

import SwiftUI

struct SidebarLogsView: View {
    @State private var filterstring: String = ""

    var body: some View {
        ZStack {
            TabView {
                LogListAlllogsView(filterstring: $filterstring)
                    .tabItem {
                        Text("All logs")
                    }

                LogsbyConfigurationView(filterstring: $filterstring)
                    .tabItem {
                        Text("By task")
                    }
            }
        }
        .padding()
    }
}
