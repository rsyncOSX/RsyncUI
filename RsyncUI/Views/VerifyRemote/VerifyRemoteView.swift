//
//  VerifyRemoteView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import OSLog
import SwiftUI

enum DestinationVerifyView: Hashable {
    case pushpullview(configID: SynchronizeConfiguration.ID)
    case executenpushpullview(configID: SynchronizeConfiguration.ID)
}

struct Verify: Hashable, Identifiable {
    let id = UUID()
    var task: DestinationVerifyView
}

struct VerifyRemoteView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var activeSheet: SheetType?

    @State private var selectedconfig: SynchronizeConfiguration?
    // Selected task is halted
    @State private var selectedtaskishalted: Bool = false
    // Adjusted output rsync
    @State private var isadjusted: Bool = false
    // Decide push or pull
    @State private var pushorpull = ObservableVerifyRemotePushPull()
    @State private var pushpullcommand = PushPullCommand.none
    @State private var verifypath: [Verify] = []

    var body: some View {
        NavigationStack(path: $verifypath) {
            VStack {
                ZStack {
                    ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                                configurations: rsyncUIdata.configurations)
                        .onChange(of: selecteduuids) {
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
                }

                Toggle("Adjust output", isOn: $isadjusted)
                    .toggleStyle(.switch)
            }
            .onAppear {
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
            .navigationTitle("Verify remote")
            .navigationDestination(for: Verify.self) { which in
                makeView(view: which.task)
            }
            .toolbar(content: {
                if remoteconfigurations, alltasksarehalted() == false {
                    ToolbarItem {
                        Button {
                            guard let selectedconfig else { return }
                            guard selectedtaskishalted == false else { return }
                            verifypath.append(Verify(task: .pushpullview(configID: selectedconfig.id)))
                        } label: {
                            Image(systemName: "arrow.up")
                        }
                        .buttonStyle(.borderedProminent)
                        .help("Verify selected")
                    }
                }

                ToolbarItem {
                    Button {
                        guard let selectedconfig else { return }
                        verifypath.append(Verify(task: .executenpushpullview(configID: selectedconfig.id)))
                    } label: {
                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                    }
                    .help("Pull or push")
                }

                ToolbarItem {
                    Spacer()
                }

                ToolbarItem {
                    Button {
                        activeSheet = nil
                    } label: {
                        Image(systemName: "return")
                    }
                    .help("Dismiss")
                    .buttonStyle(.borderedProminent)
                }
            })
        }
        .padding(10)
    }

    @MainActor @ViewBuilder
    func makeView(view: DestinationVerifyView) -> some View {
        switch view {
        case let .executenpushpullview(config):
            if let index = rsyncUIdata.configurations?.firstIndex(where: { $0.id == config }) {
                if let config = rsyncUIdata.configurations?[index] {
                    ExecutePushPullView(pushorpull: $pushorpull,
                                        pushpullcommand: $pushpullcommand,
                                        config: config)
                }
            }
        case let .pushpullview(config):
            if let index = rsyncUIdata.configurations?.firstIndex(where: { $0.id == config }) {
                if let config = rsyncUIdata.configurations?[index] {
                    PushPullView(pushorpull: $pushorpull,
                                 verifypath: $verifypath,
                                 pushpullcommand: $pushpullcommand,
                                 config: config,
                                 isadjusted: isadjusted)
                }
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
}
