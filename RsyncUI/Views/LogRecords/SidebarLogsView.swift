//
//  SidebarLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/03/2021.
//

import SwiftUI

struct SidebarLogsView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations

    var body: some View {
        if let configurations = rsyncUIdata.configurations {
            LogsbyConfigurationView(rsyncUIlogrecords: rsyncUIlogrecords,
                                    profile: rsyncUIdata.profile,
                                    configurations: configurations)
                .padding()
        }
    }

    var rsyncUIlogrecords: RsyncUIlogrecords {
        let logrecordsdata = ReadLogRecordsfromstore(rsyncUIdata.profile, rsyncUIdata.validhiddenIDs)
        return RsyncUIlogrecords(rsyncUIdata.profile, logrecordsdata.logrecords, logrecordsdata.logs)
    }
}
