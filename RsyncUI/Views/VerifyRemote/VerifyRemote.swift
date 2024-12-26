//
//  VerifyRemote.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import OSLog
import SwiftUI

enum VerifyDestinationView: String, Identifiable {
    case verify, executepushpull
    var id: String { rawValue }
}

struct VerifyTasks: Hashable, Identifiable {
    let id = UUID()
    var task: VerifyDestinationView
}

struct VerifyRemote: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var verifynavigation: [VerifyTasks]
    @Binding var queryitem: URLQueryItem?

    @State private var selectedconfig: SynchronizeConfiguration?
    @State private var selectedconfiguuid = Set<SynchronizeConfiguration.ID>()

    var body: some View {
        NavigationStack(path: $verifynavigation) {
            ListofTasksLightView(selecteduuids: $selectedconfiguuid,
                                 profile: rsyncUIdata.profile,
                                 configurations: configurations)
                .onChange(of: selectedconfiguuid) {
                    if let configurations = rsyncUIdata.configurations {
                        if let index = configurations.firstIndex(where: { $0.id == selectedconfiguuid.first }) {
                            selectedconfig = configurations[index]
                        } else {
                            selectedconfig = nil
                        }
                    }
                }
                .overlay { if configurations.count == 0 {
                    ContentUnavailableView {
                        Label("The Verify remote is for networked configurations only.", systemImage: "doc.richtext.fill")
                    } description: {
                        VStack {
                            Text("Version 3.x of rsync must be installed and enabled to use this function.")
                            Text("A networked configuration is where destination is on a remote server.")
                        }
                    }
                }
                }

            if configurations.count > 0 {
                MessageView(mytext: "**Warning:** This function is advisory only. You are solely responsible for verifying\n the correctness of the subsequent action. Performing an incorrect operation may result in data loss.", size: .title2)
            }
        }
        .navigationTitle("Verify remote")
        .navigationDestination(for: VerifyTasks.self) { which in
            makeView(view: which.task)
        }
        .onChange(of: rsyncUIdata.profile) {
            selectedconfig = nil
        }
        .toolbar(content: {
            if let selectedconfig, selectedconfig.offsiteServer.isEmpty == false,
               SharedReference.shared.rsyncversion3
            {
                ToolbarItem {
                    Button {
                        verifynavigation.append(VerifyTasks(task: .verify))
                    } label: {
                        Image(systemName: "play.fill")
                            .foregroundColor(.blue)
                    }
                    .help("Check remote")
                }
            }

            if let selectedconfig, selectedconfig.offsiteServer.isEmpty == false,
               SharedReference.shared.rsyncversion3
            {
                ToolbarItem {
                    Button {
                        verifynavigation.append(VerifyTasks(task: .executepushpull))
                    } label: {
                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .help("Pull or push")
                }
            }

            ToolbarItem {
                Button {
                    abort()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .help("Abort (⌘K)")
            }
        })
    }

    @MainActor @ViewBuilder
    func makeView(view: VerifyDestinationView) -> some View {
        switch view {
        case .verify:
            if let selectedconfig {
                DetailsPushPullView(rsyncUIdata: rsyncUIdata,
                                    verifynavigation: $verifynavigation,
                                    queryitem: $queryitem,
                                    config: selectedconfig)
            }
        case .executepushpull:
            if let selectedconfig {
                ExecutePushPullView(verifynavigation: $verifynavigation,
                                    config: selectedconfig, profile: rsyncUIdata.profile)
            }
        }
    }

    func abort() {
        InterruptProcess()
    }

    var configurations: [SynchronizeConfiguration] {
        rsyncUIdata.configurations?.filter { configuration in
            configuration.offsiteServer.isEmpty == false &&
                configuration.task == SharedReference.shared.synchronize &&
                SharedReference.shared.rsyncversion3 == true
        } ?? []
    }
}
