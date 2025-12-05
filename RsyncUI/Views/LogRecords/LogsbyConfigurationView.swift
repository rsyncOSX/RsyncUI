//
//  LogsbyConfigurationView.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 04/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import SwiftUI

@MainActor
struct LogsbyConfigurationView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations

    @State private var hiddenID = -1
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var selectedloguuids = Set<Log.ID>()
    // Alert for delete
    @State private var confirmdelete = false
    // Filterstring
    @State private var filterstring: String = ""
    @State private var showindebounce: Bool = false

    @State private var logrecords: [LogRecords]?
    @State private var logs: [Log] = []

    var body: some View {
        VStack {
            HStack {
                ZStack {
                    ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                                configurations: configurations)
                        .onChange(of: selecteduuids) {
                            if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                                hiddenID = configurations[index].hiddenID
                            } else {
                                hiddenID = -1
                            }
                            Task {
                                if filterstring.isEmpty == false {
                                    Task {
                                        let actorreadlogs = ActorReadLogRecordsJSON()
                                        logs = await actorreadlogs.updatelogsbyfilter(logrecords, filterstring, hiddenID) ?? []
                                    }
                                } else {
                                    Task {
                                        let actorreadlogs = ActorReadLogRecordsJSON()
                                        logs = await actorreadlogs.updatelogsbyhiddenID(logrecords, hiddenID) ?? []
                                    }
                                }
                            }
                        }
                        .overlay {
                            if configurations.count == 0 {
                                ContentUnavailableView {
                                    Label("No tasks", systemImage: "doc.richtext.fill")
                                } description: {
                                    Text("Add tasks in Tasks")
                                }
                            }
                        }
                }

                Table(logs, selection: $selectedloguuids) {
                    TableColumn("Date") { data in
                        Text(data.date.localized_string_from_date())
                    }

                    TableColumn("Result") { data in
                        if let result = data.resultExecuted {
                            Text(result)
                        }
                    }
                }
                .onDeleteCommand {
                    confirmdelete = true
                }
                .confirmationDialog(selectedloguuids.count == 1 ? "Delete 1 log" :
                    "Delete \(selectedloguuids.count) logs",
                    isPresented: $confirmdelete)
                {
                    Button("Delete", role: .destructive) {
                        Task {
                            await deletelogs(selectedloguuids)
                        }
                    }
                }
                .overlay { if logs.count == 0 {
                    ContentUnavailableView {
                        Label("There are no logs by this filter", systemImage: "doc.richtext.fill")
                    } description: {
                        Text("Try to search for other filter in Date or Result")
                    }
                } else if showindebounce {
                    ContentUnavailableView {
                        Label("Sorting logs", systemImage: "doc.richtext.fill")
                    } description: {}
                }
                }
            }

            HStack {
                if showindebounce {
                    indebounce

                } else {
                    if selecteduuids.isEmpty {
                        Text(logs.count == 1 ? "ALL logrecords, select task for logrecords by task: 1 log" : "ALL logrecords, select task for logrecords by task: \(logs.count) logs")

                        if filterstring.isEmpty == false {
                            Label("Filtered by: \(filterstring)", systemImage: "magnifyingglass")
                        }

                    } else {
                        Text(logs.count == 1 ? "Logrecords by selected task: 1 log" : "Logrecords by selected task: \(logs.count) logs")

                        if filterstring.isEmpty == false {
                            Label("Filtered by: \(filterstring)", systemImage: "magnifyingglass")
                        }
                    }
                }

                Spacer()
            }
        }
        .navigationTitle("Log listing")
        .searchable(text: $filterstring)
        .task {
            let actorreadlogs = ActorReadLogRecordsJSON()
            logrecords = await actorreadlogs.readjsonfilelogrecords(rsyncUIdata.profile, validhiddenIDs)
            logs = await actorreadlogs.updatelogsbyhiddenID(logrecords, hiddenID) ?? []
        }
        .onChange(of: filterstring) {
            showindebounce = true
            Task {
                try await Task.sleep(seconds: 1)
                showindebounce = false
                if filterstring.isEmpty == false {
                    Task {
                        let actorreadlogs = ActorReadLogRecordsJSON()
                        logs = await actorreadlogs.updatelogsbyfilter(logrecords, filterstring, hiddenID) ?? []
                    }
                } else {
                    Task {
                        let actorreadlogs = ActorReadLogRecordsJSON()
                        logs = await actorreadlogs.updatelogsbyhiddenID(logrecords, hiddenID) ?? []
                    }
                }
            }
        }
        .onChange(of: rsyncUIdata.profile) {
            Task {
                logs = []
                logrecords = nil
                showindebounce = true
                try await Task.sleep(seconds: 1)
                showindebounce = false
                selecteduuids.removeAll()
                selectedloguuids.removeAll()

                let actorreadlogs = ActorReadLogRecordsJSON()
                logrecords = await actorreadlogs.readjsonfilelogrecords(rsyncUIdata.profile, validhiddenIDs)
                logs = await actorreadlogs.updatelogsbyhiddenID(logrecords, hiddenID) ?? []
            }
        }
        .toolbar(content: {
            ToolbarItem {
                Button {
                    selectedloguuids.removeAll()
                    selecteduuids.removeAll()
                } label: {
                    if selectedloguuids.count == 0 {
                        Image(systemName: "clear")
                            .foregroundColor(Color(.blue))
                    } else {
                        Image(systemName: "clear")
                            .foregroundColor(Color(.red))
                            .overlay(HStack(alignment: .top) {
                                Image(systemName:
                                    String(selectedloguuids.count <= 50 ? selectedloguuids.count : 50))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                            }
                            .frame(maxHeight: .infinity)
                            .symbolVariant(.fill)
                            .symbolVariant(.circle)
                            .allowsHitTesting(false)
                            .offset(x: 10, y: -10)
                            )
                    }
                }
                .help("Reset selections")
            }
        })
        .padding()
    }

    var indebounce: some View {
        ProgressView()
            .controlSize(.small)
    }

    var validhiddenIDs: Set<Int> {
        var temp = Set<Int>()
        if let configurations = rsyncUIdata.configurations {
            for config in configurations {
                temp.insert(config.hiddenID)
            }
        }
        return temp
    }

    var configurations: [SynchronizeConfiguration] {
        if let configurations = rsyncUIdata.configurations {
            configurations
        } else {
            []
        }
    }

    func deletelogs(_ uuids: Set<UUID>) async {
        Task {
            // Start both async operations, and make sure to await the intermediate result before using it
            async let updatedRecords: [LogRecords]? = ActorReadLogRecordsJSON().deletelogs(
                uuids,
                logrecords: logrecords,
                profile: rsyncUIdata.profile,
                validhiddenIDs: validhiddenIDs
            )

            let records = await updatedRecords
            async let updatedLogs: [Log]? = ActorReadLogRecordsJSON().updatelogsbyhiddenID(records, hiddenID)

            logrecords = records
            logs = await (updatedLogs ?? [])

            WriteLogRecordsJSON(rsyncUIdata.profile, records)
            selectedloguuids.removeAll()
        }
    }
}
