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
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    @State private var selectedconfig: Configuration?

    var body: some View {
        TabView {
            Usersettings()
                .tabItem {
                    Text(NSLocalizedString("Settings", comment: "user settings"))
                }
            Sshsettings(selectedconfig: $selectedconfig.onChange { rsyncOSXData.update() },
                        reload: $reload)
                .tabItem {
                    Text(NSLocalizedString("Ssh", comment: "user settings"))
                }
            Othersettings()
                .tabItem {
                    Text(NSLocalizedString("Paths", comment: "user settings"))
                }
            JSONView(selectedprofile: $selectedprofile, reload: $reload)
                .tabItem {
                    Text(NSLocalizedString("JSON", comment: "user settings"))
                }
        }
        .alert(isPresented: errorhandling.isPresentingAlert, content: {
            Alert(localizedError: errorhandling.activeError!)

        })
        .frame(minWidth: 600, minHeight: 400)
        .padding()
    }
}
