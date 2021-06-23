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
                    Label(NSLocalizedString("Ssh", comment: "user settings"), systemImage: "terminal")
                }
            Othersettings()
                .tabItem {
                    Label(NSLocalizedString("Paths", comment: "user settings"), systemImage: "play.square")
                }
            AboutView()
                .tabItem {
                    Label(NSLocalizedString("Info", comment: "user settings"), systemImage: "info.circle.fill")
                }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 400)
    }
}
