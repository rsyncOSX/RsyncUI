//
//  LogListAlllogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/03/2021.
//

import SwiftUI

struct LogListAlllogsView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @Binding var reload: Bool
    @Binding var selectedprofile: String?

    @State private var selectedlog: Log?
    @State private var selecteduuids = Set<UUID>()

    var body: some View {
        Form {
            List(selection: $selectedlog) {
                ForEach(logrecords) { record in
                    LogRow(selecteduuids: $selecteduuids, logrecord: record)
                        .tag(record)
                }
            }
            Text("Number of logs: \(numberoflogs)")

            Spacer()

            HStack {
                Spacer()

                Button(NSLocalizedString("Select", comment: "Dismiss button")) { select() }
                    .buttonStyle(PrimaryButtonStyle())

                Button(NSLocalizedString("Delete", comment: "Dismiss button")) { delete() }
                    .buttonStyle(AbortButtonStyle())
            }
        }
        .padding()
    }

    var logrecords: [Log] {
        if let logrecords = rsyncOSXData.rsyncdata?.scheduleData.getalllogs() {
            return logrecords.sorted(by: \.date, using: >)
        }
        return []
    }

    var numberoflogs: Int {
        if let logrecords = rsyncOSXData.rsyncdata?.scheduleData.getalllogs() {
            return logrecords.count
        }
        return 0
    }
}

extension LogListAlllogsView {
    func delete() {}

    func select() {
        if let selectedlog = selectedlog {
            if selecteduuids.contains(selectedlog.id) {
                selecteduuids.remove(selectedlog.id)
            } else {
                selecteduuids.insert(selectedlog.id)
            }
        }
    }
}
