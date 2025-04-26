//
//  VerifyRemote.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import OSLog
import SwiftUI

struct VerifyRemote: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    // @Binding var verifynavigationispresented: Bool
    @Binding var urlcommandverify: Bool
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @State private var selectedconfig: SynchronizeConfiguration?
    
    
    // Selected task is halted
    @State private var selectedtaskishalted: Bool = false

    var body: some View {
        NavigationStack {
            HStack {
                ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                            profile: rsyncUIdata.profile,
                                            configurations: rsyncUIdata.configurations)
                    .onChange(of: selecteduuids) {
                        if let configurations = rsyncUIdata.configurations {
                            if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                                selectedconfig = configurations[index]
                                if selectedconfig?.task == SharedReference.shared.halted {
                                    selectedtaskishalted = true
                                } else {
                                    selectedtaskishalted = false
                                }
                            } else {
                                selectedconfig = nil
                            }
                        }
                    }

                VStack {
                    Text("**Warning:** The Verify function is advisory only.")
                        .foregroundColor(.blue)
                        .font(.title)

                    HStack {
                        Text("Select a task and select the ")
                            .foregroundColor(.blue)
                            .font(.title)

                        Text(Image(systemName: "bolt.shield"))
                            .foregroundColor(.yellow)
                            .font(.title)

                        Text(" on the toolbar to verify.")
                            .foregroundColor(.blue)
                            .font(.title)
                    }
                }
            }
            .navigationTitle("Verify remote select")
            .navigationDestination(isPresented: $urlcommandverify) {
                if let selectedconfig {
                    PushPullView(config: selectedconfig)
                }
            }
            .toolbar(content: {
                if remoteconfigurations, alltasksarehalted() == false {
                    ToolbarItem {
                        Button {
                            guard selectedtaskishalted == false else { return }
                            if urlcommandverify {
                                urlcommandverify = false
                            } else {
                                urlcommandverify = true
                            }
                        } label: {
                            Image(systemName: "bolt.shield")
                                .foregroundColor(Color(.yellow))
                        }
                        .help("Verify Selected")
                    }
                }
            })
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

/*
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
            queryitem = nil
        }
    }
 */
}
