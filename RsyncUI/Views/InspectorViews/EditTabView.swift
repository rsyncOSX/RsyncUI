//
//  EditTabView.swift
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

struct EditTabView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @State private var selectedTab: InspectorTab = .edit
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var addFirstTask: Bool = false
    // Show Inspector view, if true shwo inspectors by default on both views

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if addFirstTask {
                AddFirstTask(
                    rsyncUIdata: rsyncUIdata,
                    addFirstTask: $addFirstTask
                )
            } else {
                // Shared task list table on the left
                ListofTasksAddView(
                    rsyncUIdata: rsyncUIdata,
                    selecteduuids: $selecteduuids
                )
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
            }
        }
        .onAppear {
            // No tasks added, must show the Add button
            if rsyncUIdata.configurations == nil {
                addFirstTask = true
            }
            if let config = rsyncUIdata.configurations {
                if config.count == 0 {
                    addFirstTask = true
                }
            }
        }
        .inspector(isPresented: .constant(true)) {
            if addFirstTask {
                VStack(alignment: .leading, spacing: 12) {
                        Text("There is no task added, please add task using the form.\n")
                        
                        Text("For your own safety, please read the user doc\n")
                        + Text("Getting Started").bold()
                        + Text(", ")
                        + Text("Important").bold()
                        + Text(" about the ")
                        + Text("--delete").font(.system(.body, design: .monospaced))
                        + Text(" parameter.\n")
                        
                        Text("The ")
                        + Text("--delete").font(.system(.body, design: .monospaced))
                        + Text(" parameter is disabled by default.\n")
                        
                        Text("If Synchronize ID is ")
                        + Text("blue").foregroundColor(.blue)
                        + Text(" the parameter is disabled.\n")
                        
                        Text("If the Synchronize ID is ")
                        + Text("red").foregroundColor(.red)
                        + Text(" parameter is enabled.")
                    }
                    .padding()
                    .font(.title2)
                /*
                Text(important)
                    .font(.title2)
                    .padding()
                 */
            } else if selecteduuids.count == 0 {
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
    
    let important = """
        There is no task added please add task using the form.
        
        For your own safety, please read the user doc 
        Getting Started, Important about the --delete parameter.
        
        The --delete parameter is disabled by default.
        
        If Synchronize ID is blue the parameter is disabled.
        
        If the Synchronize ID is red parameter is enabled.
        """
}
