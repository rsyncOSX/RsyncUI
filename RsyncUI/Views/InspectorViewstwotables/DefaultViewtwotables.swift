//
//  DefaultViewtwotables.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 28/12/2025.
//

import SwiftUI

enum InspectorTabtwotables: Hashable {
    case edit
    case parameters
}

struct DefaultViewtwotables: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @State private var selectedTab: InspectorTabtwotables = .edit

    var body: some View {
        TabView(selection: $selectedTab) {
            AddTaskViewtwotables(rsyncUIdata: rsyncUIdata, selectedTab: $selectedTab)
                .tabItem {
                    Label("Edit", systemImage: "plus.circle")
                }
                .tag(InspectorTab.edit)
                .id(InspectorTab.edit)

            RsyncParametersViewtwotables(rsyncUIdata: rsyncUIdata, selectedTab: $selectedTab)
                .tabItem {
                    Label("Parameters", systemImage: "slider.horizontal.3")
                }
                .tag(InspectorTab.parameters)
                .id(InspectorTab.parameters)
        }
    }
}
