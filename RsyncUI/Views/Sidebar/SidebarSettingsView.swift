//
//  SettingsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 01/02/2021.
//

import SwiftUI

struct SidebarSettingsView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @EnvironmentObject var errorhandling: ErrorHandling

    @State private var selectedconfig: Configuration?

    var body: some View {
        TabView {
            Usersettings()
                .tabItem {
                    Text(NSLocalizedString("Settings", comment: "user settings"))
                }
            Sshsettings(selectedconfig: $selectedconfig.onChange { rsyncOSXData.update() })
                .tabItem {
                    Text(NSLocalizedString("Ssh settings", comment: "user settings"))
                }
            Othersettings()
                .tabItem {
                    Text(NSLocalizedString("Paths", comment: "user settings"))
                }
        }
        .alert(isPresented: errorhandling.isPresentingAlert, content: {
            Alert(localizedError: errorhandling.activeError!)

        })
        .frame(minWidth: 600, minHeight: 400)
        .padding()
    }
}
