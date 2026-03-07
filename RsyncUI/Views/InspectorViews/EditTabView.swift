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
    @State private var notasks: Bool = false

    var body: some View {
        HStack {
            if notasks {
                HStack {
                    
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
                
            }
        }
        .task(id: rsyncUIdata.configurations) {
            if let config = rsyncUIdata.configurations, config.isEmpty {
                notasks = true
            } else {
                notasks = false
            }
        }
        .inspector(isPresented: Binding(
            get: { !notasks },
            set: { notasks = !$0 }
        )) {
            InspectorView(rsyncUIdata: rsyncUIdata, selecteduuids: $selecteduuids)
        }
    }
}
