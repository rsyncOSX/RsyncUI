//
//  Sidebar.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 11/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import SwiftUI

enum NavigationItem {
    case rsync
    case logs
    case singletasks
    case estimation
    case none
    case snapshots
    case configurations
    case schedules
    case restore
    case quicktask
    case tabletest
}

struct Sidebar: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @EnvironmentObject var errorhandling: ErrorHandling

    @State private var selection: NavigationItem? = Optional.none
    @Binding var reload: Bool
    @Binding var selectedprofile: String?

    var sidebar: some View {
        List(selection: $selection) {
            Spacer()

            Group {
                NavigationLink(destination: SidebarMultipletasksView(reload: $reload),
                               tag: NavigationItem.estimation,
                               selection: $selection) {
                    Label(NSLocalizedString("Multiple tasks", comment: "sidebar"),
                          systemImage: "arrowshape.turn.up.left.2.fill")
                }
                .tag(NavigationItem.estimation)

                NavigationLink(destination: SidebarSingleTasksView(reload: $reload)
                    .environmentObject(OutputFromRsync()),
                    tag: NavigationItem.singletasks,
                    selection: $selection) {
                    Label(NSLocalizedString("Single task", comment: "sidebar"),
                          systemImage: "arrowshape.turn.up.backward.fill")
                }
                .tag(NavigationItem.singletasks)

                NavigationLink(destination: QuicktaskView(),
                               tag: NavigationItem.quicktask,
                               selection: $selection) {
                    Label(NSLocalizedString("Quick task", comment: "sidebar"),
                          systemImage: "arrowshape.turn.up.backward.fill")
                }
                .tag(NavigationItem.quicktask)

                NavigationLink(destination: ConfigurationsTable(),
                               tag: NavigationItem.tabletest,
                               selection: $selection) {
                    Label(NSLocalizedString("Table test", comment: "sidebar"),
                          systemImage: "arrowshape.turn.up.backward.fill")
                }
                .tag(NavigationItem.tabletest)
            }

            Divider()

            Group {
                NavigationLink(destination: SidebarAddConfigurationsView(selectedprofile: $selectedprofile,
                                                                         reload: $reload),
                               tag: NavigationItem.configurations,
                               selection: $selection) {
                    Label(NSLocalizedString("Configurations", comment: "sidebar"), systemImage: "text.badge.plus")
                }
                .tag(NavigationItem.configurations)

                NavigationLink(destination: SidebarSnapshotsView(reload: $reload),
                               tag: NavigationItem.snapshots,
                               selection: $selection) {
                    Label(NSLocalizedString("Snapshots", comment: "sidebar"), systemImage: "text.badge.plus")
                }
                .tag(NavigationItem.snapshots)
            }

            Divider()

            Group {
                NavigationLink(destination: SidebarRsyncParameter(reload: $reload),
                               tag: NavigationItem.rsync,
                               selection: $selection) {
                    Label(NSLocalizedString("Rsync parameters", comment: "sidebar"), systemImage: "command.circle.fill")
                }
                .tag(NavigationItem.rsync)

                NavigationLink(destination: SidebarSchedulesView(selectedprofile: $selectedprofile, reload: $reload),
                               tag: NavigationItem.schedules,
                               selection: $selection) {
                    Label(NSLocalizedString("Schedules", comment: "sidebar"), systemImage: "calendar.badge.plus")
                }
                .tag(NavigationItem.schedules)
            }

            Divider()

            Group {
                NavigationLink(destination: SidebarLogsView(reload: $reload,
                                                            selectedprofile: $selectedprofile),
                               tag: NavigationItem.logs,
                               selection: $selection) {
                    Label(NSLocalizedString("Log listings", comment: "sidebar"), systemImage: "text.alignleft")
                }
                .tag(NavigationItem.logs)

                NavigationLink(destination: SidebareRestoreView(),
                               tag: NavigationItem.restore,
                               selection: $selection) {
                    Label(NSLocalizedString("Restore", comment: "sidebar"), systemImage: "text.alignleft")
                }
                .tag(NavigationItem.restore)
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 200)
        .frame(width: 200)
        .alert(isPresented: errorhandling.isPresentingAlert, content: {
            Alert(localizedError: errorhandling.activeError!)
        })
    }

    var body: some View {
        NavigationView {
            sidebar

            VStack {
                imagersyncosx

                Text(NSLocalizedString("Select task", comment: "sidebar") + " ...")
                    .foregroundColor(.secondary)
                    .font(.title)
            }
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }

    var imagersyncosx: some View {
        Image("rsyncosx")
            .resizable()
            .aspectRatio(1.0, contentMode: .fit)
            .frame(maxWidth: 64)
    }
}
