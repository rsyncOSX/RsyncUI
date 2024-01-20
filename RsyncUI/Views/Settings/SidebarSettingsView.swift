//
//  SidebarSettingsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/01/2024.
//

import Foundation
import SwiftUI

struct SidebarSettingsView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedprofile: String?

    @State private var alerterror = AlertError()
    @State private var selectedsetting: SideSettingsbaritems = .settings

    var body: some View {
        NavigationSplitView {
            Divider()

            List(SideSettingsbaritems.allCases, selection: $selectedsetting) { selectedsetting in
                NavigationLink(value: selectedsetting) {
                    SidebarSettingsRow(sidebaritem: selectedsetting)
                }
            }
            .toolbar(removing: .sidebarToggle)
        } detail: {
            settingsView(selectedsetting)
        }
        .onAppear {
            Task {
                await Rsyncversion().getrsyncversion()
            }
        }
    }

    @ViewBuilder
    func settingsView(_ view: SideSettingsbaritems) -> some View {
        switch view {
        case .settings:
            Usersettings()
                .environment(alerterror)
        case .ssh:
            Sshsettings(uniqueserversandlogins: rsyncUIdata.getuniqueserversandlogins() ?? [])
                .environment(alerterror)
        case .environment:
            Othersettings()
        case .info:
            AboutView()
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
