//
//  EditTabView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 28/12/2025.
//

import SwiftUI

struct EditTabView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var hasTasks: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if !hasTasks {
                VStack {
                    AddFirstTask(rsyncUIdata: rsyncUIdata)
                    
                    VStack(alignment: .leading, spacing: 12) {
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
                }
                
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
            updateAddFirstTask()
        }
        .onChange(of: rsyncUIdata.configurations?.count) { oldValue, newValue in
            updateAddFirstTask()
        }
        .inspector(isPresented: .constant(hasTasks)) {
            InspectorView(rsyncUIdata: rsyncUIdata, selecteduuids: $selecteduuids)
        }

    }
    func updateAddFirstTask() {
        if let config = rsyncUIdata.configurations {
            hasTasks = !config.isEmpty
        } else {
            hasTasks = false
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
