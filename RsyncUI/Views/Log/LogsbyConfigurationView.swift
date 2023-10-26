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
                        logrecords.activelogrecords = logrecords.alllogssorted
                    }
                    Task {
                        if hiddenID == -1 {
                            await logrecordsbyfilter()
                        } else {
                            await logrecordsbyhiddenIDandfilter()
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
                .overlay {
                    if logrecords.activelogrecords?.count == 0 {
                        ContentUnavailableView.search
                    }
                }
            }

            HStack {
                Text(numberoflogs)

                Spacer()

                // Debounce textfield is not shown, only used for debounce entering
                // filtervalues
                DebounceTextField(label: "", value: $filterstring) { value in
                    Task {
                        if logrecords.activelogrecords?.count ?? 0 > 0, value.isEmpty == false {
                            if hiddenID == -1 {
                                await logrecordsbyfilter()
                            } else {
                                await logrecordsbyhiddenIDandfilter()
                            }
                        } else {
                            logrecords.activelogrecords = logrecords.alllogssorted
                        }
                    }
                }
                .frame(width: 300)
                .opacity(0)
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

    func logrecordsbyfilter() async {
        if filterstring.isEmpty == false {
            logrecords.filterlogs(filterstring)
        }
    }

    func logrecordsbyhiddenIDandfilter() async {
        if filterstring.isEmpty == true {
            logrecords.filterlogsbyhiddenID(hiddenID)
        } else {
            logrecords.filterlogsbyhiddenIDandfilter(filterstring, hiddenID)
        }
    }
}
