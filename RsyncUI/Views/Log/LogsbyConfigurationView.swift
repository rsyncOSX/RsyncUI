//
//  LogsGroup.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 04/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct LogsbyConfigurationView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @State private var filterstring: String = ""
    @State private var selecteduuids = Set<Configuration.ID>()
    @State private var selectedloguuids = Set<Log.ID>()
    @State private var reload: Bool = false
    @State private var hiddenID = -1
    // Alert for delete
    @State private var showAlertfordelete = false
    // Delete logs
    @State private var focusdeletelog: Bool = false

    var logrecords: RsyncUIlogrecords

    var body: some View {
        VStack {
            HStack {
                ZStack {
                    ListofTasksLightView(
                        selecteduuids: $selecteduuids
                    )
                    .onChange(of: selecteduuids) {
                        let selected = rsyncUIdata.configurations?.filter { config in
                            selecteduuids.contains(config.id)
                        }
                        if (selected?.count ?? 0) == 1 {
                            if let config = selected {
                                hiddenID = config[0].hiddenID
                            }
                        } else {
                            hiddenID = -1
                        }
                    }

                    if focusdeletelog { labeldeletetask }
                }

                if hiddenID == -1 {
                    Table(logrecords.filterlogs(filterstring) ?? [], selection: $selectedloguuids) {
                        TableColumn("Date") { data in
                            Text(data.date.localized_string_from_date())
                        }

                        TableColumn("Result") { data in
                            if let result = data.resultExecuted {
                                Text(result)
                            }
                        }
                    }
                } else {
                    Table(logrecords.filterlogsbyhiddenID(filterstring, hiddenID) ?? [], selection: $selectedloguuids) {
                        TableColumn("Date") { data in
                            Text(data.date.localized_string_from_date())
                        }

                        TableColumn("Result") { data in
                            if let result = data.resultExecuted {
                                Text(result)
                            }
                        }
                    }
                }
            }

            HStack {
                Text(numberoflogs)

                Spacer()
            }
        }
        .focusedSceneValue(\.deletetask, $focusdeletelog)
        .searchable(text: $filterstring)
        .toolbar(content: {
            ToolbarItem {
                Button {
                    selectedloguuids.removeAll()
                } label: {
                    Image(systemName: "eraser")
                }
                .tooltip("Execute")
            }

            ToolbarItem {
                Button {
                    showAlertfordelete = true
                } label: {
                    Image(systemName: "trash")
                }
                .tooltip("Delete (⌘D)")
            }
        })
        .sheet(isPresented: $showAlertfordelete) {
            DeleteLogsView(selecteduuids: $selectedloguuids,
                           selectedprofile: rsyncUIdata.profile,
                           logrecords: logrecords)
                .onDisappear {
                    focusdeletelog = false
                }
        }
    }

    var numberoflogs: String {
        if hiddenID == -1 {
            return NSLocalizedString("Number of logs", comment: "") + ": " +
                "\((logrecords.filterlogs(filterstring) ?? []).count)"
        } else {
            return NSLocalizedString("Number of logs", comment: "") + ": " +
                "\((logrecords.filterlogsbyhiddenID(filterstring, hiddenID) ?? []).count)"
        }
    }

    var labeldeletetask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                showAlertfordelete = true
            })
    }
}
