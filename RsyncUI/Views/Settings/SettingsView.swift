//
//  SettingsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 01/02/2021.
//

import Observation
import SwiftUI

struct SettingsView: View {
    @State private var alerterror = AlertError()

    @Binding var selectedprofile: String?

    var body: some View {
        TabView {
            Usersettings()
                .environment(alerterror)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
            Sshsettings(uniqueserversandlogins: ReadConfigurationJSON(profile).getuniqueserversandlogins() ?? [])
                .environment(alerterror)
                .tabItem {
                    Label("Ssh", systemImage: "terminal")
                }
            Othersettings()
                .tabItem {
                    Label("Environment", systemImage: "gear")
                }
            AboutView()
                .tabItem {
                    Label("Info", systemImage: "info.circle.fill")
                }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 450)
        .onAppear {
            Task {
                await Rsyncversion().getrsyncversion()
            }
        }
    }

    var profile: String? {
        if selectedprofile == SharedReference.shared.defaultprofile || selectedprofile == nil {
            return nil
        } else {
            return selectedprofile
        }
    }
}
