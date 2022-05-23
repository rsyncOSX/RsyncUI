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
    case multipletasks
    case none
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

    var sidebar: some View {
        List(selection: $selection) {
            Spacer()

            Group {
                NavigationLink(destination: SidebarMultipletasksView(reload: $reload,
                                                                     selection: $selection)
                        .environmentObject(OutputFromRsync()),
                    tag: NavigationItem.multipletasks,
                    selection: $selection) {
                        Label("Synchronize",
                              systemImage: "arrowshape.turn.up.left.2.fill")
                    }
                    .tag(NavigationItem.multipletasks)

                NavigationLink(destination: SidebarQuicktaskView(),
                               tag: NavigationItem.quicktask,
                               selection: $selection) {
                    Label("Quick synchronize",
                          systemImage: "arrowshape.turn.up.backward.fill")
                }
                .tag(NavigationItem.quicktask)
            }

            Divider()

            Group {
                NavigationLink(destination: SidebarAddConfigurationsView(selectedprofile: $selectedprofile,
                                                                         reload: $reload),
                               tag: NavigationItem.configurations,
                               selection: $selection) {
                    Label("Tasks", systemImage: "text.badge.plus")
                }
                .tag(NavigationItem.configurations)

                NavigationLink(destination: SidebarParametersView(selectedprofile: $selectedprofile,
                                                                  reload: $reload),
                               tag: NavigationItem.rsync,
                               selection: $selection) {
                    Label("Rsync parameters", systemImage: "command.circle.fill")
                }
                .tag(NavigationItem.rsync)
            }

            Divider()

            NavigationLink(destination: SidebarSnapshotsView(selectedprofile: $selectedprofile,
                                                             reload: $reload),
                           tag: NavigationItem.snapshots,
                           selection: $selection) {
                Label("Snapshots", systemImage: "text.badge.plus")
            }
            .tag(NavigationItem.snapshots)

            Divider()

            Group {
                NavigationLink(destination: SidebarLogsView(selectedprofile: $selectedprofile),
                               tag: NavigationItem.logs,
                               selection: $selection) {
                    Label("Log listings", systemImage: "text.alignleft")
                }
                .tag(NavigationItem.logs)

                NavigationLink(destination: SidebareRestoreView(selectedprofile: $selectedprofile),
                               tag: NavigationItem.restore,
                               selection: $selection) {
                    Label("Restore", systemImage: "text.alignleft")
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
                Text("RsyncUI")
                    .font(.title)
            }
            .padding()
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
