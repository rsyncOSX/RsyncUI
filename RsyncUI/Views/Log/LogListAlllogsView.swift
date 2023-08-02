//
//  LogListAlllogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/03/2021.
//

import Observation
import SwiftUI

struct LogListAlllogsView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @Binding var filterstring: String
    @State private var selecteduuids = Set<UUID>()
    // Alert for delete
    @State private var showAlertfordelete = false

    var logrecords: RsyncUIlogrecords

    var body: some View {
        VStack {
            Table(filteredlogrecords, selection: $selecteduuids) {
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
                        DeleteLogsView(selecteduuids: $selecteduuids,
                                       selectedprofile: rsyncUIdata.profile,
                                       logrecords: logrecords)
                    }
            }
            .padding()
            .searchable(text: $filterstring)
        }
    }

    var numberoflogs: String {
        NSLocalizedString("Number of logs", comment: "") + ": " +
            "\(filteredlogrecords.count)"
    }

    var filteredlogrecords: [Log] {
        logrecords.filterlogs(filterstring) ?? []
    }
}
