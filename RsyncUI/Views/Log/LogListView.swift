//
//  LogList.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 21/01/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct LogListView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @Binding var selectedconfig: Configuration?
    @Binding var selectedlog: Log?
    @Binding var selecteduuids: Set<UUID>

    var body: some View {
        List(selection: $selectedlog) {
            ForEach(logrecords) { record in
                LogRow(selecteduuids: $selecteduuids, logrecord: record)
                    .tag(record)
            }
        }
    }

    var logrecords: [Log] {
        if let logrecords = rsyncOSXData.rsyncdata?.scheduleData.getalllogsbyhiddenID(hiddenID: selectedconfig?.hiddenID ?? -1) {
            return logrecords.sorted(by: \.date, using: >)
        }
        return []
    }

    var numberoflogs: Int {
        if let logrecords = rsyncOSXData.rsyncdata?.scheduleData.getalllogsbyhiddenID(hiddenID: selectedconfig?.hiddenID ?? -1) {
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
