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
        LogsbyConfigurationView(rsyncUIdata: rsyncUIdata)
            .padding()
    }
}
