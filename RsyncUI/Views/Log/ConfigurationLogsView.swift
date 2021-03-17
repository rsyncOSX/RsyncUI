//
//  ConfigurationLogsView.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 04/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import SwiftUI

struct ConfigurationLogsView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata

    @Binding var selectedconfig: Configuration?
    @State private var selectedlog: Log?
    @State private var selecteduuids = Set<UUID>()
    @State private var filterstring: String = ""

    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false

    var body: some View {
        SearchbarView(text: $filterstring)
            .padding(.top, -20)

        ConfigurationsList(selectedconfig: $selectedconfig,
                           selecteduuids: $selecteduuids,
                           inwork: $inwork,
                           selectable: $selectable)

        Spacer()

        List(selection: $selectedlog) {
            if let logs = filteredlogs {
                ForEach(logs) { record in
                    LogRow(selecteduuids: $selecteduuids, logrecord: record)
                        .tag(record)
                }
            }
        }

        Spacer()

        HStack {
            Text(numberoflogs)

            Spacer()

            Button(NSLocalizedString("Clear", comment: "Select button")) { selecteduuids.removeAll() }
                .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Select", comment: "Select button")) { select() }
                .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("All", comment: "Select button")) { selectall() }
                .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Delete", comment: "Delete button")) { delete() }
                .buttonStyle(AbortButtonStyle())
        }
    }

    var filteredlogs: [Log]? {
        rsyncOSXData.rsyncdata?.scheduleData.getalllogsbyhiddenID(hiddenID: selectedconfig?.hiddenID ?? -1)?.filter {
            filterstring.isEmpty ? true : $0.dateExecuted?.contains(filterstring) ?? false ||
                filterstring.isEmpty ? true : $0.resultExecuted?.contains(filterstring) ?? false
        }
    }

    var numberoflogs: String {
        NSLocalizedString("Number of logs", comment: "") + ": " + "\(filteredlogs?.count ?? 0)"
    }
}

extension ConfigurationLogsView {
    func delete() {
        _ = NotYetImplemented()
    }

    func select() {
        if let selectedlog = selectedlog {
            if selecteduuids.contains(selectedlog.id) {
                selecteduuids.remove(selectedlog.id)
            } else {
                selecteduuids.insert(selectedlog.id)
            }
        }
    }

    func selectall() {}
}
