//
//  LogsGroup.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 04/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import SwiftUI

struct LogsbyConfigurationView: View {
    @EnvironmentObject var logrecords: RsyncUIlogrecords
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedprofile: String?
    @Binding var filterstring: String
    @Binding var focusselectlog: Bool

    @State private var selectedlog: Log?
    @State private var selectedlogsuuids = Set<UUID>()
    @State private var selecteduuids = Set<Configuration.ID>()
    @StateObject var selectedconfig = Selectedconfig()

    // Not used but requiered in parameter
    @State private var inwork = -1
    // Alert for delete
    @State private var showAlertfordelete = false

    @State private var reload: Bool = false
    @State private var confirmdelete: Bool = false

    let selectable = false

    var body: some View {
        Form {
            ListofTasksView(
                selecteduuids: $selecteduuids.onChange {
                    let selected = rsyncUIdata.configurations?.filter { config in
                        selecteduuids.contains(config.id)
                    }
                    if (selected?.count ?? 0) == 1 {
                        if let config = selected {
                            selectedconfig.config = config[0]
                        }
                    } else {
                        selectedconfig.config = nil
                    }
                },
                inwork: $inwork,
                filterstring: $filterstring,
                reload: $reload,
                confirmdelete: $confirmdelete
            )

            Spacer()

            Table(logrecords.filterlogsbyhiddenID(filterstring, selectedconfig.config?.hiddenID ?? -1) ?? [],
                  selection: $selectedlogsuuids)
            {
                TableColumn("Date") { data in
                    Text(data.date.localized_string_from_date())
                }

                TableColumn("Result") { data in
                    if let result = data.resultExecuted {
                        Text(result)
                    }
                }
            }

            Spacer()

            HStack {
                Text(numberoflogs)

                Spacer()

                Button("Delete") { showAlertfordelete = true }
                    .buttonStyle(AbortButtonStyle())
                    .sheet(isPresented: $showAlertfordelete) {
                        DeleteLogsView(selecteduuids: $selectedlogsuuids,
                                       selectedprofile: $selectedprofile)
                    }
            }
        }
        .padding()
    }

    var numberoflogs: String {
        NSLocalizedString("Number of logs", comment: "") + ": " +
            "\(logrecords.filterlogsbyhiddenID(filterstring, selectedconfig.config?.hiddenID ?? -1)?.count ?? 0)"
    }
}

// swiftlint:enable line_length
