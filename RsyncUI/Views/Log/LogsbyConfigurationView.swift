//
//  LogsbyConfigurationView.swift
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

    var logrecords: RsyncUIlogrecords

    var body: some View {
        VStack {
            HStack {
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
                    Task {
                        if hiddenID == -1 {
                            await test1()
                        } else {
                            await test2()
                        }
                    }
                }

                Table(logrecords.activelogrecords ?? [], selection: $selectedloguuids) {
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
                    showAlertfordelete = true
                }
                .onChange(of: filterstring) {
                    Task {
                        if hiddenID == -1 {
                            await test1()
                        } else {
                            await test2()
                        }
                    }
                }
            }

            HStack {
                Text(numberoflogs)

                Spacer()
            }
        }
        .searchable(text: $filterstring)
        .toolbar(content: {
            ToolbarItem {
                Button {
                    selectedloguuids.removeAll()
                } label: {
                    Image(systemName: "eraser")
                }
                .tooltip("Reset selections")
            }
        })
        .sheet(isPresented: $showAlertfordelete) {
            DeleteLogsView(selecteduuids: $selectedloguuids,
                           selectedprofile: rsyncUIdata.profile,
                           logrecords: logrecords)
        }
    }

    var numberoflogs: String {
        return NSLocalizedString("Number of logs", comment: "") + ": " +
            "\((logrecords.activelogrecords ?? []).count)"
    }

    func test1() async {
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        logrecords.filterlogs(filterstring)
    }

    func test2() async {
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        logrecords.filterlogsbyhiddenID(filterstring, hiddenID)
    }
}
