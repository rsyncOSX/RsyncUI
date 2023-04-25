//
//  SidebarVentura.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 25/04/2023.
//

import SwiftUI

enum Sidebaritems: String, Identifiable, CaseIterable {
    case synchronize, quick_synchronize, rsync_parameters, tasks, snapshots, log_listings, restore
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
                        Label("", systemImage: "text.badge.plus")
                    case .log_listings:
                        Label("", systemImage: "text.alignleft")
                    case .rsync_parameters:
                        Label("", systemImage: "command.circle.fill")
                    case .restore:
                        Label("", systemImage: "text.alignleft")
                    case .snapshots:
                        Label("", systemImage: "text.badge.plus")
                    case .synchronize:
                        Label("", systemImage: "arrowshape.turn.up.left.2.fill")
                    case .quick_synchronize:
                        Label("", systemImage: "arrowshape.turn.up.backward.fill")
                    }
                    NavigationLink(
                        selectedview.rawValue.localizedCapitalized.replacingOccurrences(of: "_", with: " "),
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
        case .log_listings:
            SidebarLogsView(selectedprofile: $selectedprofile)
        case .rsync_parameters:
            SidebarParametersView(selectedprofile: $selectedprofile, reload: $reload)
        case .restore:
            SidebareRestoreView(selectedprofile: $selectedprofile)
        case .snapshots:
            SidebarSnapshotsView(selectedprofile: $selectedprofile, reload: $reload)
        case .synchronize:
            SidebarTasksView(reload: $reload, selection: $selection)
        case .quick_synchronize:
            SidebarQuicktaskView()
        }
    }

    @available(macOS 13.0, *)
    var body: some View {
        sidebarventura
    }
}
