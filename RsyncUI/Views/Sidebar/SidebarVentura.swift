//
//  SidebarVentura.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 25/04/2023.
//

import SwiftUI

enum Sidebaritems: String, Identifiable, CaseIterable {
    case tasks, loglistings, parameters, restore, snapshots, synchronize, quicktask
    var id: String { rawValue }
}

@available(macOS 13.0, *)
struct SidebarVentura: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @EnvironmentObject var errorhandling: ErrorHandling
    @Binding var reload: Bool
    @Binding var selectedprofile: String?
    @Binding var selection: NavigationItem?

    @State private var selectedview: Sidebaritems = .synchronize

    @available(macOS 13.0, *)
    var sidebarventura: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List(Sidebaritems.allCases, selection: $selectedview) { selectedview in
                HStack {
                    switch selectedview {
                    case .tasks:
                        Label("Tasks", systemImage: "text.badge.plus")
                    case .loglistings:
                        Label("Log listings", systemImage: "text.alignleft")
                    case .parameters:
                        Label("Rsync parameters", systemImage: "command.circle.fill")
                    case .restore:
                        Label("Restore", systemImage: "text.alignleft")
                    case .snapshots:
                        Label("Snapshots", systemImage: "text.badge.plus")
                    case .synchronize:
                        Label("Synchronize", systemImage: "arrowshape.turn.up.left.2.fill")
                    case .quicktask:
                        Label("Quick synchronize", systemImage: "arrowshape.turn.up.backward.fill")
                    }
                    NavigationLink(
                        selectedview.rawValue.localizedCapitalized,
                        value: selectedview
                    )
                }
            }
        } detail: {
            makeSheet(selectedview)
        }
    }

    @ViewBuilder
    func makeSheet(_ view: Sidebaritems) -> some View {
        switch view {
        case .tasks:
            SidebarAddTaskView(selectedprofile: $selectedprofile, reload: $reload)
        case .loglistings:
            SidebarLogsView(selectedprofile: $selectedprofile)
        case .parameters:
            SidebarParametersView(selectedprofile: $selectedprofile, reload: $reload)
        case .restore:
            SidebareRestoreView(selectedprofile: $selectedprofile)
        case .snapshots:
            SidebarSnapshotsView(selectedprofile: $selectedprofile, reload: $reload)
        case .synchronize:
            SidebarTasksView(reload: $reload, selection: $selection)
        case .quicktask:
            SidebarQuicktaskView()
        }
    }

    @available(macOS 13.0, *)
    var body: some View {
        sidebarventura
    }
}
