//
//  VerifyRemote.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import OSLog
import SwiftUI

enum DestinationVerifyView: String, Identifiable {
    case pushpullview, executenpushpullview

    var id: String { rawValue }
}

struct Verify: Hashable, Identifiable {
    let id = UUID()
    var task: DestinationVerifyView
}

struct VerifyRemoteView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var verifypath: [Verify]
    @Binding var urlcommandverify: Bool
    // Queryitem binding is requiered for external URL only
    @Binding var queryitem: URLQueryItem?

    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var selectedconfig: SynchronizeConfiguration?
    // Selected task is halted
    @State private var selectedtaskishalted: Bool = false

    var body: some View {
        NavigationStack(path: $verifypath) {
            VStack {
                ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                            configurations: rsyncUIdata.configurations)
                    .onChange(of: selecteduuids) {
                        queryitem = nil
                        if let configurations = rsyncUIdata.configurations {
                            if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                                selectedconfig = configurations[index]
                                if selectedconfig?.task == SharedReference.shared.halted {
                                    selectedtaskishalted = true
                                    selectedconfig = nil
                                } else {
                                    selectedtaskishalted = false
                                }
                            } else {
                                selectedconfig = nil
                            }
                        }
                    }

                VStack {
                    Text("**Warning**: Verify remote is **advisory** only.")
                        .foregroundColor(.blue)
                        .font(.title)

                    HStack {
                        Text("Select a task and select the ")
                            .foregroundColor(.blue)
                            .font(.title2)

                        Text(Image(systemName: "bolt.shield"))
                            .foregroundColor(.yellow)
                            .font(.title2)

                        Text(" on the toolbar to verify.")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
            }
            .navigationTitle("Verify remote")
            .navigationDestination(for: Verify.self) { which in
                makeView(view: which.task)
            }
            .toolbar(content: {
                if remoteconfigurations, alltasksarehalted() == false {
                    ToolbarItem {
                        Button {
                            guard selectedconfig != nil else { return }
                            guard selectedtaskishalted == false else { return }

                            verifypath.append(Verify(task: .pushpullview))

                        } label: {
                            Image(systemName: "bolt.shield")
                                .foregroundColor(Color(.yellow))
                        }
                        .help("Verify Selected")
                    }
                }

                ToolbarItem {
                    Button {
                        guard selectedconfig != nil else { return }

                        verifypath.append(Verify(task: .executenpushpullview))

                    } label: {
                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .help("Pull or push")
                }
            })
        }
        .onChange(of: queryitem) {
            guard queryitem != nil else { return }
            handlequeryitem()
        }
    }

    @MainActor @ViewBuilder
    func makeView(view: DestinationVerifyView) -> some View {
        switch view {
        case .executenpushpullview:
            if let selectedconfig {
                ExecutePushPullView(config: selectedconfig)
            }

        case .pushpullview:
            if let selectedconfig {
                PushPullView(config: selectedconfig)
            }
        }
    }

    var remoteconfigurations: Bool {
        let remotes = rsyncUIdata.configurations?.filter { configuration in
            configuration.offsiteServer.isEmpty == false &&
                configuration.task == SharedReference.shared.synchronize &&
                SharedReference.shared.rsyncversion3 == true
        } ?? []
        if remotes.count > 0 {
            return true
        } else {
            return false
        }
    }

    func alltasksarehalted() -> Bool {
        let haltedtasks = rsyncUIdata.configurations?.filter { $0.task == SharedReference.shared.halted }
        return haltedtasks?.count ?? 0 == rsyncUIdata.configurations?.count ?? 0
    }

    // URL code
    func handlequeryitem() {
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
            verifypath.append(Verify(task: .pushpullview))

            queryitem = nil
        }
    }
}
