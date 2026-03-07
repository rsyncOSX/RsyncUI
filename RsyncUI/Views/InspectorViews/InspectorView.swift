//
//  InspectorView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 28/12/2025.
//

import SwiftUI

enum InspectorTab: Hashable {
    case edit
    case parameters
    case logview
    case verifytask
}

struct InspectorView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @State private var selectedTab: InspectorTab = .edit

    var body: some View {
        if selecteduuids.count == 0 {
            Text("No task\nselected")
                .font(.title2)
        } else {
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

                LogRecordsTabView(
                    rsyncUIdata: rsyncUIdata,
                    selectedTab: $selectedTab,
                    selecteduuids: $selecteduuids
                )
                .tabItem {
                    Label("Log Records", systemImage: "slider.horizontal.3")
                }
                .tag(InspectorTab.logview)
                .id(InspectorTab.logview)

                VerifyTaskTabView(
                    rsyncUIdata: rsyncUIdata,
                    selectedTab: $selectedTab,
                    selecteduuids: $selecteduuids
                )
                .tabItem {
                    Label("Verify Task", systemImage: "slider.horizontal.3")
                }
                .tag(InspectorTab.verifytask)
                .id(InspectorTab.verifytask)
            }
            .padding()
            .navigationTitle("")
            .inspectorColumnWidth(min: 550, ideal: 600, max: 650)
        }
    }
}
