//
//  SidebarSettingsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 01/02/2021.
//

import Observation
import SwiftUI

enum SideSettingsbaritems: String, Identifiable, CaseIterable {
    case rsync_and_path, monitor_and_log, ssh, environment, info
    var id: String { rawValue }
}

struct SidebarSettingsView: View {
    @State private var alerterror = AlertError()
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
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            Rsyncversion().getrsyncversion()
        }
        .navigationTitle("Settings")
    }

    @MainActor @ViewBuilder
    func settingsView(_ view: SideSettingsbaritems) -> some View {
        switch view {
        case .rsync_and_path:
            RsyncandPathsettings()
                .environment(alerterror)
        case .monitor_and_log:
            Logsettings()
                .environment(alerterror)
        case .ssh:
            NavigationStack {
                Sshsettings()
                    .environment(alerterror)
            }
        case .environment:
            Environmentsettings()
        case .info:
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
        case .info:
            "info.circle.fill"
        }
    }
}
