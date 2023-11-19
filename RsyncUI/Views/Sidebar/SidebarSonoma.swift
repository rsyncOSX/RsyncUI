//
//  SidebarSonoma.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 13/11/2023.
//

import SwiftUI

@available(macOS 14.0, *)
struct SidebarSonoma: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @EnvironmentObject var errorhandling: AlertError
    @Binding var reload: Bool
    @Binding var selectedprofile: String?
    @Binding var selecteduuids: Set<Configuration.ID>
    @State private var selectedview: Sidebaritems?

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
            selectView(selectedview ?? .synchronize)
        }
        .alert(isPresented: errorhandling.presentalert, content: {
            Alert(localizedError: errorhandling.activeError!)
        })
    }

    @ViewBuilder
    func selectView(_ view: Sidebaritems) -> some View {
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
            if SharedReference.shared.usenavigationstack {
                NavigationStack {
                    NavigationSidebarTasksView(selecteduuids: $selecteduuids, reload: $reload)
                }
            } else {
                SidebarTasksView(selecteduuids: $selecteduuids, reload: $reload)
            }
        case .quick_synchronize:
            QuicktaskView()
        }
    }
}
