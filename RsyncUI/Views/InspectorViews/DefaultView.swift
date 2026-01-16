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
    // Show Inspector view, if true shwo inspectors by default on both views
    @State var showinspector: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Shared task list table on the left
            ListofTasksAddView(rsyncUIdata: rsyncUIdata, selecteduuids: $selecteduuids)
                .frame(minWidth: 300)
                .onChange(of: rsyncUIdata.profile) {
                    selecteduuids.removeAll()
                }
                .overlay {
                    if let config = rsyncUIdata.configurations, config.isEmpty {
                        ContentUnavailableView {
                            Label("There are no tasks added",
                                  systemImage: "doc.richtext.fill")
                        } description: {
                            Text("Select the + button on the toolbar to add a task")
                        }
                    }
                }

            Divider()

            // Tab-specific inspector views on the right
            TabView(selection: $selectedTab) {
                AddTaskView(rsyncUIdata: rsyncUIdata,
                            selectedTab: $selectedTab,
                            selecteduuids: $selecteduuids,
                            showinspector: $showinspector)
                    .tabItem {
                        Label("Edit", systemImage: "plus.circle")
                    }
                    .tag(InspectorTab.edit)
                    .id(InspectorTab.edit)

                RsyncParametersView(rsyncUIdata: rsyncUIdata,
                                    selectedTab: $selectedTab,
                                    selecteduuids: $selecteduuids,
                                    showinspector: $showinspector)
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
