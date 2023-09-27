//
//  Sidebar.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/07/2023.
//

import SwiftUI

enum Sidebaritems: String, Identifiable, CaseIterable {
    case synchronize, quick_synchronize, rsync_parameters, tasks, snapshots, log_listings, restore
    var id: String { rawValue }
}

struct Sidebar: View {
    @SwiftUI.Environment(ErrorHandling.self) var errorhandling
    @Binding var reload: Bool
    @Binding var selectedprofile: String?
    @Binding var selecteduuids: Set<Configuration.ID>

    @State private var selectedview: Sidebaritems = .synchronize

    // Keep record of actions
    var actions: Actions

    var body: some View {
        NavigationSplitView {
            Divider()

            List(Sidebaritems.allCases, selection: $selectedview) { selectedview in
                NavigationLink(value: selectedview) {
                    SidebarRow(sidebaritem: selectedview)
                }
                if selectedview == .quick_synchronize ||
                    selectedview == .tasks ||
                    selectedview == .snapshots { Divider() }
            }

            Text(selectedprofile ?? "")
                .padding()
                .font(.footnote)

        } detail: {
            makeView(selectedview)
        }
        .alert(isPresented: errorhandling.isPresentingAlert, content: {
            Alert(localizedError: errorhandling.activeError!)
        })
    }

    @ViewBuilder
    func makeView(_ view: Sidebaritems) -> some View {
        switch view {
        case .tasks:
            SidebarAddTaskView(selectedprofile: $selectedprofile, reload: $reload)
        case .log_listings:
            SidebarLogsView()
        case .rsync_parameters:
            SidebarParametersView(reload: $reload)
        case .restore:
            SidebareRestoreView()
        case .snapshots:
            SidebarSnapshotsView(reload: $reload)
        case .synchronize:
            SidebarTasksView(selecteduuids: $selecteduuids, reload: $reload, actions: actions)
        case .quick_synchronize:
            QuicktaskView()
        }
    }
}

struct SidebarRow: View {
    var sidebaritem: Sidebaritems

    var body: some View {
        Label(sidebaritem.rawValue.localizedCapitalized.replacingOccurrences(of: "_", with: " "),
              systemImage: systemimage(sidebaritem))
    }

    func systemimage(_ view: Sidebaritems) -> String {
        switch view {
        case .tasks:
            return "text.badge.plus"
        case .log_listings:
            return "text.alignleft"
        case .rsync_parameters:
            return "command.circle.fill"
        case .restore:
            return "arrowshape.turn.up.forward"
        case .snapshots:
            return "text.badge.plus"
        case .synchronize:
            return "arrowshape.turn.up.backward"
        case .quick_synchronize:
            return "arrowshape.turn.up.left.2"
        }
    }
}
