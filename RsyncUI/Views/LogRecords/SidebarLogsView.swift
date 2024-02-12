//
//  SidebarLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/03/2021.
//

import SwiftUI

struct SidebarLogsView: View {
    let configurations: [SynchronizeConfiguration]
    let profile: String?

    var body: some View {
        LogsbyConfigurationView(rsyncUIlogrecords: rsyncUIlogrecords,
                                profile: profile,
                                configurations: configurations)
            .padding()
    }

    var rsyncUIlogrecords: RsyncUIlogrecords {
        let logrecordsdata = ReadLogRecordsfromstore(profile, validhiddenIDs)
        return RsyncUIlogrecords(profile, logrecordsdata.logrecords, logrecordsdata.logs)
    }

    var validhiddenIDs: Set<Int> {
        var temp = Set<Int>()
        for i in 0 ..< configurations.count {
            temp.insert(configurations[i].hiddenID)
        }
        return temp
    }
}
