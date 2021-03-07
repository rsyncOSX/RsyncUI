//
//  Sidebar.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 11/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct Sidebar: View {
    enum NavigationItem {
        case rsync
        case logs
        case singletasks
        case estimation
        case settings
        case none
        case snapshots
        case configurations
        case schedules
    }

    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @State private var selection: NavigationItem? = Optional.none
    @Binding var reload: Bool
    @Binding var selectedprofile: String?

    var sidebar: some View {
        List(selection: $selection) {
            Spacer()

            Group {
                NavigationLink(destination: SidebarEstimationView(reload: $reload),
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

                NavigationLink(destination: SidebarSchedulesView(selectedprofile: $selectedprofile, reload: $reload),
                               tag: NavigationItem.schedules,
                               selection: $selection) {
                    Label(NSLocalizedString("Schedules", comment: "sidebar"), systemImage: "text.badge.plus")
                }
                .tag(NavigationItem.schedules)

                NavigationLink(destination: SidebarSnapshotsView(reload: $reload),
                               tag: NavigationItem.snapshots,
                               selection: $selection) {
                    Label(NSLocalizedString("Snapshots", comment: "sidebar"), systemImage: "text.badge.minus")
                }
                .tag(NavigationItem.snapshots)
            }

            Divider()

            Group {
                NavigationLink(destination: SidebarLogsView(),
                               tag: NavigationItem.logs,
                               selection: $selection) {
                    Label(NSLocalizedString("List logs", comment: "sidebar"), systemImage: "text.alignleft")
                }
                .tag(NavigationItem.logs)

                NavigationLink(destination: SidebarRsyncCommandView(),
                               tag: NavigationItem.rsync,
                               selection: $selection) {
                    Label(NSLocalizedString("Rsync commands", comment: "sidebar"), systemImage: "command.circle.fill")
                }
                .tag(NavigationItem.rsync)
            }

            Divider()

            Group {
                NavigationLink(destination: SidebarSettingsView(),
                               tag: NavigationItem.settings,
                               selection: $selection) {
                    Label(NSLocalizedString("Settings", comment: "sidebar"), systemImage: "gearshape")
                }
                .tag(NavigationItem.settings)
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 200)
        .frame(width: 200)
    }

    var body: some View {
        NavigationView {
            sidebar

            VStack {
                ImageRsyncOSX()

                Text(NSLocalizedString("Select a task", comment: "sidebar") + " ...")
                    .foregroundColor(.secondary)
                    .font(.title)
            }
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}
