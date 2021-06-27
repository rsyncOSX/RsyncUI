//
//  SettingsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 01/02/2021.
//

import SwiftUI

struct SidebarSettingsView: View {
    @Binding var selectedprofile: String?
    var body: some View {
        TabView {
            Usersettings()
                .tabItem {
                    Label(NSLocalizedString("Settings", comment: "user settings"), systemImage: "gear")
                }
            Sshsettings(uniqueserversandlogins: ReadConfigurationJSON(profile).getuniqueserversandlogins() ?? [])
                .tabItem {
                    Label(NSLocalizedString("Ssh", comment: "user settings"), systemImage: "terminal")
                }
            Othersettings()
                .tabItem {
                    Label(NSLocalizedString("Paths", comment: "user settings"), systemImage: "play")
                }
            AboutView()
                .tabItem {
                    Label(NSLocalizedString("About", comment: "user settings"), systemImage: "info")
                }
        }
        .frame(minWidth: 800, minHeight: 400)
        .padding()
    }

    var profile: String? {
        if selectedprofile == NSLocalizedString("Default profile", comment: "default profile")
            || selectedprofile == nil
        {
            return nil
        } else {
            return selectedprofile
        }
    }
}
