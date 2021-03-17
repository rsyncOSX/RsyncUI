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

        LogListView(selectedconfig: $selectedconfig,
                    selectedlog: $selectedlog,
                    selecteduuids: $selecteduuids)

        Spacer()

        HStack {
            Text(labelnumberoflogs)

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

    var numberoflogsbyconfig: Int {
        if let logrecords = rsyncOSXData.rsyncdata?.scheduleData.getalllogsbyhiddenID(hiddenID: selectedconfig?.hiddenID ?? -1) {
            return logrecords.count
        }
        return 0
    }

    var labelnumberoflogs: String {
        NSLocalizedString("Number of logs", comment: "") + ": " + "\(numberoflogsbyconfig)"
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
