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

    var body: some View {
        TabView {
            LogsbyConfigurationView()
                .tabItem {
                    Text(NSLocalizedString("By config", comment: "logsview"))
                }
            LogListAlllogsView(reload: $reload, selectedprofile: $selectedprofile)
                .tabItem {
                    Text(NSLocalizedString("All logs", comment: "logsview"))
                }
        }
        .alert(isPresented: errorhandling.isPresentingAlert, content: {
            Alert(localizedError: errorhandling.activeError!)

        })
        .padding()
    }

    var logrecords: [Log] {
        if let logrecords = rsyncOSXData.rsyncdata?.scheduleData.getalllogs() {
            return logrecords.sorted(by: \.date, using: >)
        }
        return []
    }
}
