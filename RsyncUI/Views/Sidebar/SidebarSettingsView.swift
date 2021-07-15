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
                    Label("Paths", systemImage: "play.square")
                }
            AboutView()
                .tabItem {
                    Label("Info", systemImage: "info.circle.fill")
                }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 500)
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
