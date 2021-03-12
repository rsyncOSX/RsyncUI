//
//  SidebarLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/03/2021.
//

import SwiftUI

struct SidebarLogsView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @EnvironmentObject var errorhandling: ErrorHandling
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    @State private var selectedconfig: Configuration?

    @State private var alllogs: [Log]?

    var body: some View {
        let binding = Binding(
            get: { rsyncOSXData.rsyncdata?.scheduleData.getalllogs() },
            set: { alllogs = $0 }
        )

        TabView {
            LogsbyConfigurationView()
                .tabItem {
                    Text(NSLocalizedString("By config", comment: "logsview"))
                }
            LogListAlllogsView(reload: $reload, logrecords: binding)
                .tabItem {
                    Text(NSLocalizedString("All logs", comment: "logsview"))
                }
        }
        .alert(isPresented: errorhandling.isPresentingAlert, content: {
            Alert(localizedError: errorhandling.activeError!)

        })
        .padding()
    }
}
