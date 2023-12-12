//
//  SidebarSheetView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/07/2023.
//

import SwiftUI

struct SidebarSheetView: View {
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
            SidebarAddTaskView(selectedprofile: $selectedprofile,
                               reload: $reload,
                               profilenames: profilenames)
        case .log_listings:
            SidebarLogsView()
        case .rsync_parameters:
            SidebarParametersView(reload: $reload)
        case .restore:
            RestoreTableView()
        case .snapshots:
            SnapshotsView(reload: $reload)
        case .synchronize:
            SidebarTasksView(selecteduuids: $selecteduuids, reload: $reload)
        case .quick_synchronize:
            QuicktaskView()
        }
    }
}
