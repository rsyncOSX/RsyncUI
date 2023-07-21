//
//  Sidebar.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 11/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import SwiftUI

enum NavigationItem {
    case parameterrsync
    case logsview
    case tasksview
    case snapshots
    case configurations
    case restore
    case quicktask
}

struct Sidebar: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @EnvironmentObject var errorhandling: ErrorHandling
    @Binding var reload: Bool
    @Binding var selectedprofile: String?
    @Binding var selection: NavigationItem?

    var actions: Actions

    var sidebar: some View {
        List(selection: $selection) {
            Spacer()

            Group {
                NavigationLink(destination: SidebarTasksView(reload: $reload, actions: actions),
                               tag: NavigationItem.tasksview,
                               selection: $selection)
                {
                    Label("Synchronize",
                          systemImage: "arrowshape.turn.up.backward")
                }
                .tag(NavigationItem.tasksview)

                NavigationLink(destination: QuicktaskView(),
                               tag: NavigationItem.quicktask,
                               selection: $selection)
                {
                    Label("Quick synchronize",
                          systemImage: "arrowshape.turn.up.left.2")
                }
                .tag(NavigationItem.quicktask)
            }

            Divider()

            Group {
                NavigationLink(destination: SidebarAddTaskView(selectedprofile: $selectedprofile,
                                                               reload: $reload),
                               tag: NavigationItem.configurations,
                               selection: $selection)
                {
                    Label("Tasks", systemImage: "text.badge.plus")
                }
                .tag(NavigationItem.configurations)

                NavigationLink(destination: SidebarParametersView(reload: $reload),
                               tag: NavigationItem.parameterrsync,
                               selection: $selection)
                {
                    Label("Rsync parameters", systemImage: "command.circle.fill")
                }
                .tag(NavigationItem.parameterrsync)
            }

            Divider()

            NavigationLink(destination: SidebarSnapshotsView(reload: $reload),
                           tag: NavigationItem.snapshots,
                           selection: $selection)
            {
                Label("Snapshots", systemImage: "text.badge.plus")
            }
            .tag(NavigationItem.snapshots)

            Divider()

            Group {
                NavigationLink(destination: SidebarLogsView(),
                               tag: NavigationItem.logsview,
                               selection: $selection)
                {
                    Label("Log listings", systemImage: "text.alignleft")
                }
                .tag(NavigationItem.logsview)

                NavigationLink(destination: SidebareRestoreView(),
                               tag: NavigationItem.restore,
                               selection: $selection)
                {
                    Label("Restore", systemImage: "arrowshape.turn.up.forward")
                }
                .tag(NavigationItem.restore)
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 200)
        .alert(isPresented: errorhandling.isPresentingAlert, content: {
            Alert(localizedError: errorhandling.activeError!)
        })
    }

    var body: some View {
        NavigationView {
            sidebar
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}
