//
//  VerifyRemote.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import OSLog
import SwiftUI

enum VerifyDestinationView: String, Identifiable {
    case verify, arguments
    var id: String { rawValue }
}

struct VerifyTasks: Hashable, Identifiable {
    let id = UUID()
    var task: VerifyDestinationView
}

struct VerifyRemote: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var verifynavigation: [VerifyTasks]
    
    @State private var selectedconfig: SynchronizeConfiguration?
    @State private var selectedconfiguuid = Set<SynchronizeConfiguration.ID>()
    @State private var showdetails: Bool = false
    
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
                        Label("The Verify remote is only for networked configurations", systemImage: "doc.richtext.fill")
                    } description: {
                        Text("A networked configuration is where destination is on a remote server.")
                    }
                }
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
                SharedReference.shared.rsyncversion3 {
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
               SharedReference.shared.rsyncversion3 {
                ToolbarItem {
                    Button {
                        verifynavigation.append(VerifyTasks(task: .arguments))
                    } label: {
                        Image(systemName: "arrowshape.turn.up.forward")
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
                            OutputRsyncCheckeRemoteView(config: selectedconfig)
                        }
        case .arguments:
            ArgumentsVerifyView(rsyncUIdata: rsyncUIdata)
        }
    }

    func abort() {
        InterruptProcess()
    }

    var configurations: [SynchronizeConfiguration] {
        rsyncUIdata.configurations?.filter { configuration in
            configuration.offsiteServer.isEmpty == false
        } ?? []
    }
}
