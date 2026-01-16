//
//  DefaultViewtwotables.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 28/12/2025.
//

import SwiftUI

struct DefaultViewtwotables: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @State private var selectedTab: InspectorTab = .edit
    // Show Inspector view, if true shwo inspectors by default on both views
   
    var body: some View {
        TabView(selection: $selectedTab) {
            AddTaskViewtwotables(rsyncUIdata: rsyncUIdata,
                                 selectedTab: $selectedTab)
                .tabItem {
                    Label("Edit", systemImage: "plus.circle")
                }
                .tag(InspectorTab.edit)

            RsyncParametersViewtwotables(rsyncUIdata: rsyncUIdata,
                                         selectedTab: $selectedTab)
                .tabItem {
                    Label("Parameters", systemImage: "slider.horizontal.3")
                }
                .tag(InspectorTab.parameters)
        }
        .id(selectedTab)
    }
}
