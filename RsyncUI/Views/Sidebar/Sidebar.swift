//
//  Sidebar.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/12/2023.
//
// swiftlint:disable cyclomatic_complexity

import SwiftUI

enum Sidebaritems: String, Identifiable, CaseIterable {
    case synchronize, tasks, rsync_parameters, snapshots, log_listings, restore, rsync_output, profiles
    var id: String { rawValue }
}

struct Sidebar: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedprofile: String?
    @Bindable var errorhandling: AlertError

    @State private var estimateprogressdetails = EstimateProgressDetails()
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var selectedview: Sidebaritems = .synchronize

    var body: some View {
        NavigationSplitView {
            profilepicker
                .padding([.bottom, .top], 5)

            Divider()

            List(Sidebaritems.allCases, selection: $selectedview) { selectedview in
                NavigationLink(value: selectedview) {
                    SidebarRow(sidebaritem: selectedview)
                }

                if selectedview == .tasks || selectedview == .snapshots || selectedview == .restore { Divider() }
            }
            .listStyle(.sidebar)

            Text(SharedReference.shared.rsyncversionshort ?? "")
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

    @MainActor @ViewBuilder
    func selectView(_ view: Sidebaritems) -> some View {
        switch view {
        case .tasks:
            AddTaskView(rsyncUIdata: rsyncUIdata,
                        selectedprofile: $selectedprofile,
                        profilenames: profilenames)
        case .log_listings:
            if let configurations = rsyncUIdata.configurations {
                SidebarLogsView(configurations: configurations,
                                profile: rsyncUIdata.profile)
            }

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
            SidebarTasksView(rsyncUIdata: rsyncUIdata,
                             selecteduuids: $selecteduuids,
                             estimateprogressdetails: estimateprogressdetails)
        case .profiles:
            ProfileView(rsyncUIdata: rsyncUIdata, profilenames: profilenames, selectedprofile: $selectedprofile)
        case .rsync_output:
            if let index = estimateprogressdetails.estimatedlist?.firstIndex(where: { $0.id == selecteduuids.first }) {
                if let estimatedtask = estimateprogressdetails.estimatedlist?[index],
                   let rsyncoutput = estimateprogressdetails.estimatedlist?[index].outputfromrsync
                {
                    OutputRsyncByUUIDView(selecteduuids: $selecteduuids,
                                          estimatedtask: estimatedtask,
                                          data: rsyncoutput)
                }
            } else {
                Text("Either select a task or the task is not estimated")
                    .font(.title2)
            }
        }
    }

    var profilepicker: some View {
        HStack {
            Picker("", selection: $selectedprofile) {
                ForEach(profilenames.profiles, id: \.self) { profile in
                    Text(profile.profile ?? "")
                        .tag(profile.profile)
                }
            }
            .frame(width: 180)
            .onChange(of: selectedprofile) {
                selecteduuids.removeAll()
            }
            Spacer()
        }
    }

    var profilenames: Profilenames {
        return Profilenames()
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
        case .profiles:
            return "arrow.triangle.branch"
        case .rsync_output:
            return "text.magnifyingglass"
        }
    }
}

// swiftlint:enable cyclomatic_complexity
