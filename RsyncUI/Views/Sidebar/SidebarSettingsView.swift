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
                    Label("Settings", systemImage: "gear")
                }
            Sshsettings(uniqueserversandlogins: ReadConfigurationJSON(profile).getuniqueserversandlogins() ?? [])
                .tabItem {
                    Label("Ssh", systemImage: "terminal")
                }
            Othersettings()
                .tabItem {
                    Label("Paths", systemImage: "play")
                }
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info")
                }
        }
        .frame(minWidth: 800, minHeight: 400)
        .padding()
    }

    var profile: String? {
        if selectedprofile == "Default profile"
            || selectedprofile == nil
        {
            return nil
        } else {
            return selectedprofile
        }
    }
}
