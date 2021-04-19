//
//  SettingsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 01/02/2021.
//

import SwiftUI

struct SidebarSettingsView: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    @State private var selectedconfig: Configuration?

    var body: some View {
        TabView {
            Usersettings()
                .tabItem {
                    Text(NSLocalizedString("Settings", comment: "user settings"))
                }
            Sshsettings(selectedconfig: $selectedconfig.onChange { rsyncUIData.update() },
                        reload: $reload)
                .tabItem {
                    Text(NSLocalizedString("Ssh", comment: "user settings"))
                }
            Othersettings()
                .tabItem {
                    Text(NSLocalizedString("Paths", comment: "user settings"))
                }
        }
        .frame(minWidth: 600, minHeight: 400)
        .padding()
    }
}
