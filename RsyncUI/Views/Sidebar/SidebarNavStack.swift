//
//  SidebarNavStack.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/12/2023.
//

import SwiftUI

enum Sidebaritems: String, Identifiable, CaseIterable {
    case synchronize, quick_synchronize, rsync_parameters, tasks, snapshots, log_listings, restore
    var id: String { rawValue }
}

struct SidebarNavStack: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata

    @Binding var reload: Bool
    @Binding var selectedprofile: String?
    @Binding var selecteduuids: Set<Configuration.ID>
    @Bindable var profilenames: Profilenames
    @Bindable var errorhandling: AlertError
    @State private var selectedview: Sidebaritems = .synchronize

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
            selectView(selectedview)
        }
        .alert(isPresented: errorhandling.presentalert, content: {
            if let error = errorhandling.activeError {
                Alert(localizedError: error)
            } else {
                Alert(title: Text("No error"))
            }
        })
    }

    @ViewBuilder
    func selectView(_ view: Sidebaritems) -> some View {
        switch view {
        case .tasks:
            NavigationAddTaskView(selectedprofile: $selectedprofile, reload: $reload, profilenames: profilenames)
        case .log_listings:
            SidebarLogsView()
        case .rsync_parameters:
            NavigationRsyncParametersView(reload: $reload)
        case .restore:
            NavigationStack {
                NavigationRestoreTableView()
            }
        case .snapshots:
            SnapshotsView(reload: $reload)
        case .synchronize:
            NavigationSidebarTasksView(selecteduuids: $selecteduuids, reload: $reload)
        case .quick_synchronize:
            NavigationQuicktaskView()
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