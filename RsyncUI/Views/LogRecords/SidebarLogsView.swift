//
//  SidebarLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/03/2021.
//

import SwiftUI

struct SidebarLogsView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @State private var reload: Bool = false

    var body: some View {
        LogsbyConfigurationView(rsyncUIdata: rsyncUIdata, reload: $reload, logrecords: logrecords)
            .onChange(of: reload) {
                reload = false
            }
            .padding()
    }

    var logrecords: RsyncUIlogrecords {
        return RsyncUIlogrecords(profile: rsyncUIdata.profile, validhiddenIDs: rsyncUIdata.validhiddenIDs)
    }
}
