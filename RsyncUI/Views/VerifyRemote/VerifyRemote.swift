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
    // For supporting URL links
    @Binding var queryitem: URLQueryItem?

    @State private var selectedconfig: SynchronizeConfiguration?

    var body: some View {
        NavigationStack(path: $verifynavigation) {
            VStack {
                Text("**Warning:** This function is advisory only.")
                    .foregroundColor(.yellow)
                    .font(.title)
                  
                (
                    Text("Select a task in Synchronize view and select the ") +
                    Text(Image(systemName: "bolt.shield")) +
                    Text(" to verify.")
                )
                .foregroundColor(.yellow)
                .font(.title)
            }
        }
        .navigationTitle("Verify remote")
        .navigationDestination(for: VerifyTasks.self) { which in
            makeView(view: which.task)
        }
        .onChange(of: queryitem) {
            // URL code
            handlequeryitem()
        }
        .toolbar(content: {
           
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
                DetailsPushPullView(verifynavigation: $verifynavigation,
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

extension VerifyRemote {
    // URL code
    private func handlequeryitem() {
        Logger.process.info("VerifyRemote: Change on queryitem discovered")
        // This is from URL
        let backupid = queryitem?.value
        if let config = rsyncUIdata.configurations?.first(where: { $0.backupID.replacingOccurrences(of: " ", with: "_") == backupid }),
           config.offsiteServer.isEmpty == false,
           SharedReference.shared.rsyncversion3,
           queryitem != nil
        {
            selectedconfig = config
            guard selectedconfig?.task != SharedReference.shared.halted else { return }
            // Set config and execute a Verify
            verifynavigation.append(VerifyTasks(task: .verify))
            queryitem = nil
        }
    }
}
