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
        RsyncUIlogrecords(profile, validhiddenIDs)
    }

    var validhiddenIDs: Set<Int> {
        var temp = Set<Int>()
        _ = configurations.map { record in
            temp.insert(record.hiddenID)
        }
        return temp
    }
}
