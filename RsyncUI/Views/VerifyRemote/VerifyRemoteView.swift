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
    @Environment(\.dismiss) private var dismiss

    @State private var selectedprofileID: ProfilesnamesRecord.ID?
    @State private var configurationsdata = RsyncUIconfigurations()

    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
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
                ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                            configurations: configurationsdata.configurations)
                    .onChange(of: selecteduuids) {
                        if let configurations = configurationsdata.configurations {
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

                HStack {
                    
                    if configurationsdata.validprofiles.isEmpty == false {
                        Picker("", selection: $selectedprofileID) {
                            Text("Default")
                                .tag(nil as ProfilesnamesRecord.ID?)
                            ForEach(configurationsdata.validprofiles, id: \.self) { profile in
                                Text(profile.profilename)
                                    .tag(profile.id)
                            }
                        }
                        .frame(width: 180)
                        .padding([.bottom, .top, .trailing], 7)
                    }
                    
                    ConditionalGlassButton(
                        systemImage: "arrow.up",
                        helpText: "Verify selected"
                    ) {
                        guard let selectedconfig else { return }
                        guard selectedtaskishalted == false else { return }
                        verifypath.append(Verify(task: .pushpullview(configID: selectedconfig.id)))
                    }

                    ConditionalGlassButton(
                        systemImage: "arrow.left.arrow.right.circle.fill",
                        helpText: "Pull or push"
                    ) {
                        guard let selectedconfig else { return }
                        verifypath.append(Verify(task: .executenpushpullview(configID: selectedconfig.id)))
                    }

                    Toggle("Adjust output", isOn: $isadjusted)
                        .toggleStyle(.switch)

                    Spacer()

                    if #available(macOS 26.0, *) {
                        Button("Close", role: .close) {
                            dismiss()
                        }
                        .buttonStyle(RefinedGlassButtonStyle())

                    } else {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "return")
                        }
                        .help("Close")
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Verify remote")
            .navigationDestination(for: Verify.self) { which in
                makeView(view: which.task)
            }
        }
        .task {
            let catalognames = Homepath().getFullPathMacSerialCatalogsAsStringNames()
            configurationsdata.validprofiles = catalognames.map { catalog in
                ProfilesnamesRecord(catalog)
            }
        }
        .task(id: selectedprofileID) {
            let profile: String? = if let index = configurationsdata.validprofiles.firstIndex(where: { $0.id == selectedprofileID }) {
                configurationsdata.validprofiles[index].profilename
            } else {
                nil
            }
            configurationsdata.configurations = await ActorReadSynchronizeConfigurationJSON()
                .readjsonfilesynchronizeconfigurations(profile,
                                                       SharedReference.shared.rsyncversion3)
        }
        .padding()
    }

    @MainActor @ViewBuilder
    func makeView(view: DestinationVerifyView) -> some View {
        switch view {
        case let .executenpushpullview(configuuid):
            if let index = configurationsdata.configurations?.firstIndex(where: { $0.id == configuuid }) {
                if let config = configurationsdata.configurations?[index] {
                    ExecutePushPullView(pushorpull: $pushorpull,
                                        pushpullcommand: $pushpullcommand,
                                        config: config)
                }
            }
        case let .pushpullview(configuuid):
            if let index = configurationsdata.configurations?.firstIndex(where: { $0.id == configuuid }) {
                if let config = configurationsdata.configurations?[index] {
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
        let remotes = configurationsdata.configurations?.filter { configuration in
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
        let haltedtasks = configurationsdata.configurations?.filter { $0.task == SharedReference.shared.halted }
        return haltedtasks?.count ?? 0 == configurationsdata.configurations?.count ?? 0
    }
}
