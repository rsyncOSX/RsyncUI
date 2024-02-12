//
//  Sidebar.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/12/2023.
//

import SwiftUI

enum Sidebaritems: String, Identifiable, CaseIterable {
    case synchronize, quick_synchronize, rsync_parameters, tasks, snapshots, log_listings, restore
    var id: String { rawValue }
}

struct Sidebar: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedprofile: String?
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Bindable var profilenames: Profilenames
    @Bindable var errorhandling: AlertError
    @State private var selectedview: Sidebaritems = .synchronize
    // Focus buttons from the menu
    @State private var focusdemodata: Bool = false

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
        .focusedSceneValue(\.demodata, $focusdemodata)
        .sheet(isPresented: $focusdemodata) {
            LoadDemoDataView(rsyncUIdata: rsyncUIdata, profilenames: profilenames, selectedprofile: $selectedprofile)
        }
    }

    @ViewBuilder
    func selectView(_ view: Sidebaritems) -> some View {
        switch view {
        case .tasks:
            AddTaskView(rsyncUIdata: rsyncUIdata, selectedprofile: $selectedprofile, profilenames: profilenames)
        case .log_listings:
            SidebarLogsView(rsyncUIdata: rsyncUIdata)
        case .rsync_parameters:
            RsyncParametersView(rsyncUIdata: rsyncUIdata)
        case .restore:
            NavigationStack {
                if let configurations = rsyncUIdata.configurations {
                    RestoreTableView(profile: $rsyncUIdata.profile,
                                     configurations: configurations)
                }
            }
        case .snapshots:
            SnapshotsView(rsyncUIdata: rsyncUIdata)
        case .synchronize:
            SidebarTasksView(rsyncUIdata: rsyncUIdata, selecteduuids: $selecteduuids)
        case .quick_synchronize:
            QuicktaskView(userserver: UserServer(configurations: rsyncUIdata.configurations))
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
