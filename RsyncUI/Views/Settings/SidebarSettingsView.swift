//
//  SidebarSettingsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 01/02/2021.
//

import Observation
import SwiftUI

enum SideSettingsbaritems: String, Identifiable, CaseIterable {
    case rsync_and_path, log, ssh, environment, about
    var id: String { rawValue }
}

struct SidebarSettingsView: View {
    @State private var selectedsetting: SideSettingsbaritems = .rsync_and_path

    var body: some View {
        NavigationSplitView {
            Divider()

            List(SideSettingsbaritems.allCases, selection: $selectedsetting) { item in
                SettingsNavigationLinkWithHover(item: item, selectedview: $selectedsetting)
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
        case .log:
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
              systemImage: systemImage(sidebaritem))
    }

    func systemImage(_ view: SideSettingsbaritems) -> String {
        switch view {
        case .rsync_and_path:
            "gear"
        case .log:
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

struct SettingsNavigationLinkWithHover: View {
    let item: SideSettingsbaritems // Replace with your actual item type
    @Binding var selectedview: SideSettingsbaritems // Replace with your selection type
    @State private var isHovered = false

    var body: some View {
        NavigationLink(value: item) {
            SidebarSettingsRow(sidebaritem: item)
        }
        .listRowBackground(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color.blue.opacity(0.2) : Color.clear)
                .padding(.horizontal, 10)
        )
        .listRowInsets(EdgeInsets())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
