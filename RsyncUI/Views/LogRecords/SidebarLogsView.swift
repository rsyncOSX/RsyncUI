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
        LogsbyConfigurationView(rsyncUIdata: rsyncUIdata, logrecords: logrecords)
            .padding()
    }

    var logrecords: RsyncUIlogrecords {
        let logrecordsdata = Readlogsfromstore(rsyncUIdata.profile, rsyncUIdata.validhiddenIDs)
        return RsyncUIlogrecords(rsyncUIdata.profile, logrecordsdata.logrecords, logrecordsdata.logs)
    }
}
