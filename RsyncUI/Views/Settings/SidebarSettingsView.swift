//
//  SidebarSettingsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 01/02/2021.
//

import Observation
import SwiftUI

enum SideSettingsbaritems: String, Identifiable, CaseIterable {
    case rsync_and_path, monitor_and_log, ssh, environment, about
    var id: String { rawValue }
}

struct SidebarSettingsView: View {
    @State private var selectedsetting: SideSettingsbaritems = .rsync_and_path

    var body: some View {
        NavigationSplitView {
            Divider()

            List(SideSettingsbaritems.allCases, selection: $selectedsetting) { selectedsetting in
                NavigationLink(value: selectedsetting) {
                    SidebarSettingsRow(sidebaritem: selectedsetting)
                }
            }
            .listStyle(.sidebar)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            settingsView(selectedsetting)
        }
        .frame(minWidth: 300, minHeight: 600)
        .navigationTitle("RsyncUI settings")
    }

    @MainActor @ViewBuilder
    func settingsView(_ view: SideSettingsbaritems) -> some View {
        switch view {
        case .rsync_and_path:
            RsyncandPathsettings()
        case .monitor_and_log:
            Logsettings()
        case .ssh:
            Sshsettings()
        case .environment:
            Environmentsettings()
        case .about:
            AboutView()
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
        case .rsync_and_path:
            "gear"
        case .monitor_and_log:
            "network"
        case .ssh:
            "terminal"
        case .environment:
            "gear"
        case .about:
            "info.circle.fill"
        }
    }
}
