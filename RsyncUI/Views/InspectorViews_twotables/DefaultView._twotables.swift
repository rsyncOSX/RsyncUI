//
//  DefaultView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 28/12/2025.
//

import SwiftUI

enum InspectorTab_twotables: Hashable {
    case edit
    case parameters
}

struct DefaultView_twotables: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @State private var selectedTab: InspectorTab_twotables = .edit

    var body: some View {
        TabView(selection: $selectedTab) {
            AddTaskView_twotables(rsyncUIdata: rsyncUIdata, selectedTab: $selectedTab)
                .tabItem {
                    Label("Edit", systemImage: "plus.circle")
                }
                .tag(InspectorTab.edit)
                .id(InspectorTab.edit)

            RsyncParametersView_twotables(rsyncUIdata: rsyncUIdata, selectedTab: $selectedTab)
                .tabItem {
                    Label("Parameters", systemImage: "slider.horizontal.3")
                }
                .tag(InspectorTab.parameters)
                .id(InspectorTab.parameters)
        }
    }
}
