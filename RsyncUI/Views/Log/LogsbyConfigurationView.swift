//
//  LogsGroup.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 04/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct LogsbyConfigurationView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @Binding var filterstring: String

    @State private var selecteduuids = Set<Configuration.ID>()
    @State private var reload: Bool = false
    @State private var hiddenID = -1

    var logrecords: RsyncUIlogrecords

    var body: some View {
        VStack {
            HStack {
                ListofTasksLightView(
                    selecteduuids: $selecteduuids.onChange {
                        guard selecteduuids.count == 1 else {
                            hiddenID = -1
                            return
                        }
                        if let selected = rsyncUIdata.configurations?.filter({ $0.id == selecteduuids.first }) {
                            guard selected.count == 1 else {
                                hiddenID = -1
                                return
                            }
                            hiddenID = selected[0].hiddenID
                        }
                    }
                )

                Table(logdetails) {
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

            HStack {
                Text(numberoflogs)

                Spacer()
            }
        }
        .padding()
    }

    var numberoflogs: String {
        NSLocalizedString("Number of logs", comment: "") + ": " +
            "\(logrecords.filterlogsbyhiddenID(filterstring, hiddenID)?.count ?? 0)"
    }

    var logdetails: [Log] {
        return logrecords.filterlogsbyhiddenID(filterstring, hiddenID) ?? []
    }
}
