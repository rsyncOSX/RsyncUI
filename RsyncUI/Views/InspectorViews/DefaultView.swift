//
//  DefaultView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 28/12/2025.
//

import SwiftUI

enum InspectorTab: Hashable {
    case edit
    case parameters
    // case global
}

struct DefaultView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @State private var selectedTab: InspectorTab = .edit
    @State var selecteduuids = Set<SynchronizeConfiguration.ID>()

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Shared task list table on the left
            ListofTasksAddView(rsyncUIdata: rsyncUIdata, selecteduuids: $selecteduuids)
                .frame(minWidth: 300)
                .onChange(of: rsyncUIdata.profile) {
                    selecteduuids.removeAll()
                }

            Divider()

            // Tab-specific inspector views on the right
            TabView(selection: $selectedTab) {
                AddTaskView(rsyncUIdata: rsyncUIdata,
                            selectedTab: $selectedTab,
                            selecteduuids: $selecteduuids)
                    .tabItem {
                        Label("Edit", systemImage: "plus.circle")
                    }
                    .tag(InspectorTab.edit)
                    .id(InspectorTab.edit)

                RsyncParametersView(rsyncUIdata: rsyncUIdata,
                                    selectedTab: $selectedTab,
                                    selecteduuids: $selecteduuids)
                    .tabItem {
                        Label("Parameters", systemImage: "slider.horizontal.3")
                    }
                    .tag(InspectorTab.parameters)
                    .id(InspectorTab.parameters)
            }
            .onChange(of: selectedTab) {
                selecteduuids.removeAll()
            }
        }
    }
}

/*
 GlobalChangeTaskView(rsyncUIdata: rsyncUIdata)
 .tabItem {
 Label("Global", systemImage: "gearshape")
 }
 .tag(InspectorTab.global)
 .id(InspectorTab.global)
 */
