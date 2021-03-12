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
    @Binding var reload: Bool
    @Binding var selectedprofile: String?

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
}
