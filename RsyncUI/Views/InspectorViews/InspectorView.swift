//
//  InspectorView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 28/12/2025.
//

import SwiftUI

enum InspectorTab: Hashable {
    case edit
    case parameters
    case logview
    case verifytask
}

struct InspectorView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @State private var selectedTab: InspectorTab = .edit

    var body: some View {
        if selecteduuids.count != 1 {
            ContentUnavailableView {
                Label("Select a task", systemImage: "checklist")
            } description: {
                Text("Select one task to edit its configuration, review logs, or verify it.")
            }
        } else {
            VStack(spacing: 0) {
                if let configuration = rsyncUIdata.configurations?.first(where: { selecteduuids.contains($0.id) }) {
                    HStack {
                        Image(systemName: configuration.offsiteServer.isEmpty ? "externaldrive" : "network")
                            .font(.title2)
                            .foregroundStyle(.tint)
                        Text(configuration.backupID.isEmpty ? String(localized: "Unnamed task") : configuration.backupID)
                            .font(.title2.weight(.semibold))
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        ConfigurationTaskBadge(task: configuration.task)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                InspectorTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                Divider()

                InspectorContentView(
                    rsyncUIdata: rsyncUIdata,
                    selectedTab: $selectedTab,
                    selecteduuids: $selecteduuids
                )
            }
        }
    }
}

extension InspectorTab: CaseIterable {
    static var allCases: [InspectorTab] {
        [.edit, .parameters, .logview, .verifytask]
    }

    var title: LocalizedStringKey {
        switch self {
        case .edit: "General"
        case .parameters: "Rsync Options"
        case .logview: "Logs"
        case .verifytask: "Verify"
        }
    }

    var systemImage: String {
        switch self {
        case .edit: "gearshape"
        case .parameters: "slider.horizontal.3"
        case .logview: "list.bullet.rectangle"
        case .verifytask: "checkmark.shield"
        }
    }
}

/// Inspector tabs as icon + caption, like the Xcode inspector. The selected tab is
/// tinted with an accent line under it, so the tabs read as navigation and not as
/// buttons next to the toolbar actions.
struct InspectorTabBar: View {
    @Binding var selectedTab: InspectorTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(InspectorTab.allCases, id: \.self) { tab in
                let selected = tab == selectedTab
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 15))
                            .frame(height: 18)
                        Text(tab.title)
                            .font(.caption)
                            .fontWeight(selected ? .semibold : .regular)
                            .lineLimit(1)
                        Capsule()
                            .fill(selected ? Color.accentColor : Color.clear)
                            .frame(width: 28, height: 2)
                    }
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(tab.title))
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
    }
}
