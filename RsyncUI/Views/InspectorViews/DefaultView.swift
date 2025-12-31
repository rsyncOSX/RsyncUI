//
//  DefaultView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 28/12/2025.
//

import SwiftUI

enum InspectorTab: Hashable {
    case add
    case parameters
    case global
}

struct DefaultView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @State private var selectedTab: InspectorTab = .add

    var body: some View {
        TabView(selection: $selectedTab) {
            AddTaskView(rsyncUIdata: rsyncUIdata, selectedTab: $selectedTab)
                .tabItem {
                    Label("Add", systemImage: "plus.circle")
                }
                .tag(InspectorTab.add)
                .id(InspectorTab.add)

            RsyncParametersView(rsyncUIdata: rsyncUIdata, selectedTab: $selectedTab)
                .tabItem {
                    Label("Parameters", systemImage: "slider.horizontal.3")
                }
                .tag(InspectorTab.parameters)
                .id(InspectorTab.parameters)

            GlobalChangeTaskView(rsyncUIdata: rsyncUIdata)
                .tabItem {
                    Label("Global", systemImage: "gearshape")
                }
                .tag(InspectorTab.global)
                .id(InspectorTab.global)
        }
    }
}
