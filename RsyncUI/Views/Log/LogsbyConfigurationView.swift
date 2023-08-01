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

    @State private var selecteduuids = Set<Configuration.ID>()
    @State private var hiddenID: Int = -1
    @State private var reload: Bool = false
    @Binding var filterstring: String

    var logrecords: RsyncUIlogrecords

    var body: some View {
        VStack {
            HStack {
                ListofTasksLightView(selecteduuids: $selecteduuids)
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
