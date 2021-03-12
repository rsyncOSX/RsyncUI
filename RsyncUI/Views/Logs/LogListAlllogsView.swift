//
//  LogListAlllogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/03/2021.
//

import SwiftUI

struct LogListAlllogsView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @State private var selectedlog: Log?
    @State private var selecteduuids = Set<UUID>()

    var body: some View {
        List(selection: $selectedlog) {
            ForEach(logrecords) { record in
                LogRow(selecteduuids: $selecteduuids, logrecord: record)
                    .tag(record)
            }
        }
        Text("Number of logs: \(numberoflogs)")
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

    var header: some View {
        HStack {
        Text(NSLocalizedString("Date", comment: "loglist"))
                .modifier(FixedTag(200, .center))
            Text(NSLocalizedString("Record", comment: "loglist"))
                .modifier(FixedTag(250, .center))
        }
    }
}
