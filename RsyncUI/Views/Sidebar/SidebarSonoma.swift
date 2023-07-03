//
//  SidebarSonoma.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/07/2023.
//

import SwiftUI

@available(macOS 14.0, *)
struct SidebarSonoma: View {
    @EnvironmentObject var errorhandling: ErrorHandling
    @Binding var reload: Bool
    @Binding var selectedprofile: String?
    @State private var selectedview: Sidebaritems = .synchronize
    // Keep record of actions
    var actions: Actions

    @ViewBuilder
    func makeView(_ view: Sidebaritems) -> some View {
        switch view {
        case .tasks:
            SidebarAddTaskView(selectedprofile: $selectedprofile, reload: $reload)
        case .log_listings:
            SidebarLogsView(selectedprofile: $selectedprofile)
        case .rsync_parameters:
            SidebarParametersView(reload: $reload)
        case .restore:
            SidebareRestoreView()
        case .snapshots:
            SidebarSnapshotsView(selectedprofile: $selectedprofile, reload: $reload)
        case .synchronize:
            SidebarTasksView(reload: $reload, actions: actions)
        case .quick_synchronize:
            QuicktaskView()
        }
    }

    @available(macOS 14.0, *)
    var body: some View {
        NavigationSplitView {
            List(Sidebaritems.allCases, selection: $selectedview) { selectedview in
                NavigationLink(value: selectedview) {
                    SidebarRow(sidebaritem: selectedview)
                }
                if selectedview == .quick_synchronize ||
                    selectedview == .tasks ||
                    selectedview == .snapshots { Divider() }
            }
        } detail: {
            makeView(selectedview)
        }
    }
}
