//
//  SettingsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 01/02/2021.
//

import Observation
import SwiftUI

enum SideSettingsbaritems: String, Identifiable, CaseIterable {
    case settings, ssh, environment, info
    var id: String { rawValue }
}

struct SettingsView: View {
    @Binding var selectedprofile: String?

    @State private var alerterror = AlertError()
    @State private var selectedsetting: SideSettingsbaritems = .settings

    var body: some View {
        NavigationSplitView {
            List(SideSettingsbaritems.allCases, selection: $selectedsetting) { selectedsetting in
                NavigationLink(value: selectedsetting) {
                    SidebarSettingsRow(sidebaritem: selectedsetting)
                }
            }
        } detail: {
            settingsView(selectedsetting)
        }
        .frame(minWidth: 800, minHeight: 450)
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
            NavigationStack {
                Sshsettings(selectedprofile: $selectedprofile)
                    .environment(alerterror)
            }
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

struct SidebarSettingsRow: View {
    var sidebaritem: SideSettingsbaritems

    var body: some View {
        Label(sidebaritem.rawValue.localizedCapitalized.replacingOccurrences(of: "_", with: " "),
              systemImage: systemimage(sidebaritem))
    }

    func systemimage(_ view: SideSettingsbaritems) -> String {
        switch view {
        case .settings:
            return "gear"
        case .ssh:
            return "terminal"
        case .environment:
            return "gear"
        case .info:
            return "info.circle.fill"
        }
    }
}
