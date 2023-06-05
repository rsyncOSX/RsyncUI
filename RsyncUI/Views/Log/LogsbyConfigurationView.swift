//
//  LogsGroup.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 04/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct LogsbyConfigurationView: View {
    @EnvironmentObject var logrecords: RsyncUIlogrecords
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedprofile: String?
    @Binding var focusselectlog: Bool

    @State private var selectedlog: Log?
    @State private var selectedlogsuuids = Set<UUID>()
    @State private var selecteduuids = Set<Configuration.ID>()
    @State private var selectedconfig: Configuration?

    // Not used but requiered in parameter
    @State private var inwork = -1
    // Alert for delete
    @State private var showAlertfordelete = false

    @State private var reload: Bool = false
    @State private var confirmdelete: Bool = false

    let selectable = false

    var body: some View {
        Form {
            ListofTasksLightView(
                selecteduuids: $selecteduuids.onChange {
                    let selected = rsyncUIdata.configurations?.filter { config in
                        selecteduuids.contains(config.id)
                    }
                    if (selected?.count ?? 0) == 1 {
                        if let config = selected {
                            selectedconfig = config[0]
                        }
                    } else {
                        selectedconfig = nil
                    }
                },
                reload: $reload
            )

            Spacer()

            Table(logrecords.filterlogsbyhiddenID(selectedconfig?.hiddenID ?? -1) ?? [],
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
            }
        }
        .padding()
    }

    var numberoflogs: String {
        NSLocalizedString("Number of logs", comment: "") + ": " +
            "\(logrecords.filterlogsbyhiddenID(selectedconfig?.hiddenID ?? -1)?.count ?? 0)"
    }
}
