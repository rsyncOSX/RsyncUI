//
//  SettingsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 01/02/2021.
//

import SwiftUI

struct SidebarSettingsView: View {
    var body: some View {
        TabView {
            Usersettings()
                .tabItem {
                    Label(NSLocalizedString("Settings", comment: "user settings"), systemImage: "gear")
                }
            Sshsettings()
                .tabItem {
                    Label(NSLocalizedString("Ssh", comment: "user settings"), systemImage: "gear")
                }
            Othersettings()
                .tabItem {
                    Label(NSLocalizedString("Paths", comment: "user settings"), systemImage: "gear")
                }
        }
        .frame(minWidth: 600, minHeight: 400)
        .padding()
    }
}
