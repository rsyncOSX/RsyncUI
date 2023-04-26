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

    var sidebar: some View {
        List(selection: $selection) {
            Spacer()

            Group {
                NavigationLink(destination: SidebarTasksView(reload: $reload,
                                                             selection: $selection),
                               tag: NavigationItem.tasksview,
                               selection: $selection)
                {
                    Label("Synchronize",
                          systemImage: "arrow.triangle.2.circlepath.circle.fill")
                }
                .tag(NavigationItem.tasksview)

                NavigationLink(destination: SidebarQuicktaskView(),
                               tag: NavigationItem.quicktask,
                               selection: $selection)
                {
                    Label("Quick synchronize",
                          systemImage: "arrowshape.turn.up.backward.fill")
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

                NavigationLink(destination: SidebarParametersView(selectedprofile: $selectedprofile,
                                                                  reload: $reload),
                               tag: NavigationItem.parameterrsync,
                               selection: $selection)
                {
                    Label("Rsync parameters", systemImage: "command.circle.fill")
                }
                .tag(NavigationItem.parameterrsync)
            }

            Divider()

            NavigationLink(destination: SidebarSnapshotsView(selectedprofile: $selectedprofile,
                                                             reload: $reload),
                           tag: NavigationItem.snapshots,
                           selection: $selection)
            {
                Label("Snapshots", systemImage: "text.badge.plus")
            }
            .tag(NavigationItem.snapshots)

            Divider()

            Group {
                NavigationLink(destination: SidebarLogsView(selectedprofile: $selectedprofile),
                               tag: NavigationItem.logsview,
                               selection: $selection)
                {
                    Label("Log listings", systemImage: "text.alignleft")
                }
                .tag(NavigationItem.logsview)

                NavigationLink(destination: SidebareRestoreView(selectedprofile: $selectedprofile),
                               tag: NavigationItem.restore,
                               selection: $selection)
                {
                    Label("Restore", systemImage: "text.alignleft")
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

extension View {
    func tooltip(_ tip: String) -> some View {
        ZStack {
            background(GeometryReader { childGeometry in
                TooltipView(tip, geometry: childGeometry) {
                    self
                }
            })
            self
        }
    }
}

private struct TooltipView<Content>: View where Content: View {
    let content: () -> Content
    let tip: String
    let geometry: GeometryProxy

    init(_ tip: String, geometry: GeometryProxy, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.tip = tip
        self.geometry = geometry
    }

    var body: some View {
        Tooltip(tip, content: content)
            .frame(width: geometry.size.width, height: geometry.size.height)
    }
}

private struct Tooltip<Content: View>: NSViewRepresentable {
    typealias NSViewType = NSHostingView<Content>

    init(_ text: String?, @ViewBuilder content: () -> Content) {
        self.text = text
        self.content = content()
    }

    let text: String?
    let content: Content

    func makeNSView(context _: Context) -> NSHostingView<Content> {
        NSViewType(rootView: content)
    }

    func updateNSView(_ nsView: NSHostingView<Content>, context _: Context) {
        nsView.rootView = content
        nsView.toolTip = text
    }
}
