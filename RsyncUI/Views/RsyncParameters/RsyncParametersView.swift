//
//  RsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2023.
//

import Combine
import SwiftUI

enum ParametersDestinationView: String, Identifiable {
    case defaultparameters, verify, arguments
    var id: String { rawValue }
}

struct ParametersTasks: Hashable, Identifiable {
    let id = UUID()
    var task: ParametersDestinationView
}

struct RsyncParametersView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var rsyncnavigation: [ParametersTasks]

    @State private var parameters = ObservableParametersRsync()
    @State private var selectedconfig: SynchronizeConfiguration?
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var selectedrsynccommand = RsyncCommand.synchronize_data
    // Focus buttons from the menu
    @State private var focusaborttask: Bool = false

    // Combine for debounce of sshport and keypath
    @State var publisherport = PassthroughSubject<String, Never>()
    @State var publisherkeypath = PassthroughSubject<String, Never>()
    // Backup switch
    @State var backup: Bool = false
    // Update pressed
    @State var updated: Bool = false

    var body: some View {
        NavigationStack(path: $rsyncnavigation) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        setsshpath
                            .disabled(selectedconfig == nil)

                        setsshport
                            .disabled(selectedconfig == nil)
                    }

                    EditRsyncParameter(450, $parameters.parameter8)
                        .onChange(of: parameters.parameter8) {
                            parameters.configuration?.parameter8 = parameters.parameter8
                        }
                        .disabled(selectedconfig == nil)
                    EditRsyncParameter(450, $parameters.parameter9)
                        .onChange(of: parameters.parameter9) {
                            parameters.configuration?.parameter9 = parameters.parameter9
                        }
                        .disabled(selectedconfig == nil)
                    EditRsyncParameter(450, $parameters.parameter10)
                        .onChange(of: parameters.parameter10) {
                            parameters.configuration?.parameter10 = parameters.parameter10
                        }
                        .disabled(selectedconfig == nil)
                    EditRsyncParameter(450, $parameters.parameter11)
                        .onChange(of: parameters.parameter11) {
                            parameters.configuration?.parameter11 = parameters.parameter11
                        }
                        .disabled(selectedconfig == nil)
                    EditRsyncParameter(450, $parameters.parameter12)
                        .onChange(of: parameters.parameter12) {
                            parameters.configuration?.parameter12 = parameters.parameter12
                        }
                        .disabled(selectedconfig == nil)
                    EditRsyncParameter(450, $parameters.parameter13)
                        .onChange(of: parameters.parameter13) {
                            parameters.configuration?.parameter13 = parameters.parameter13
                        }
                        .disabled(selectedconfig == nil)
                    EditRsyncParameter(450, $parameters.parameter14)
                        .onChange(of: parameters.parameter14) {
                            parameters.configuration?.parameter14 = parameters.parameter14
                        }
                        .disabled(selectedconfig == nil)

                    Toggle("Backup", isOn: $backup)
                        .toggleStyle(.switch)
                        .onChange(of: backup) {
                            guard selectedconfig != nil else {
                                backup = false
                                return
                            }
                            parameters.setbackup()
                        }
                        .disabled(selectedconfig == nil)

                    Spacer()
                }

                ListofTasksLightView(selecteduuids: $selecteduuids,
                                     profile: rsyncUIdata.profile,
                                     configurations: rsyncUIdata.configurations ?? [])
                    .frame(maxWidth: .infinity)
                    .onChange(of: selecteduuids) {
                        if let configurations = rsyncUIdata.configurations {
                            if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                                selectedconfig = configurations[index]
                                parameters.setvalues(configurations[index])
                                if configurations[index].parameter12 != "--backup" {
                                    backup = false
                                }
                            } else {
                                selectedconfig = nil
                                parameters.setvalues(selectedconfig)
                                backup = false
                                updated = false
                            }
                        }
                    }

                if focusaborttask { labelaborttask }
            }

            RsyncCommandView(config: $parameters.configuration,
                             selectedrsynccommand: $selectedrsynccommand)
        }
        .onChange(of: rsyncUIdata.profile) {
            selectedconfig = nil
            selecteduuids.removeAll()
            parameters.setvalues(selectedconfig)
            backup = false
        }
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .toolbar(content: {
            ToolbarItem {
                Button {
                    saversyncparameters()
                } label: {
                    if updated == false {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(Color(.blue))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(.blue))
                    }
                }
                .help("Update task")
            }

            ToolbarItem {
                Button {
                    rsyncnavigation.append(ParametersTasks(task: .defaultparameters))
                } label: {
                    Image(systemName: "house.fill")
                }
                .help("Default rsync parameters")
            }

            ToolbarItem {
                Button {
                    guard selecteduuids.isEmpty == false else { return }
                    rsyncnavigation.append(ParametersTasks(task: .verify))
                } label: {
                    Image(systemName: "flag.checkered")
                }
                .help("Verify task")
            }

            ToolbarItem {
                Button {
                    rsyncnavigation.append(ParametersTasks(task: .arguments))
                } label: {
                    Image(systemName: "command")
                }
                .help("Show arguments")
            }
        })
        .navigationDestination(for: ParametersTasks.self) { which in
            makeView(view: which.task)
        }
        .padding()
    }

    @MainActor @ViewBuilder
    func makeView(view: ParametersDestinationView) -> some View {
        switch view {
        case .defaultparameters:
            RsyncDefaultParametersView(rsyncUIdata: rsyncUIdata, path: $rsyncnavigation)
        case .verify:
            if let config = parameters.configuration {
                OutputRsyncVerifyView(config: config)
            }
        case .arguments:
            ArgumentsView(rsyncUIdata: rsyncUIdata)
        }
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }

    var setsshpath: some View {
        EditValue(300, "Ssh keypath and identityfile",
                  $parameters.sshkeypathandidentityfile)
            .onChange(of: parameters.sshkeypathandidentityfile) {
                publisherkeypath.send(parameters.sshkeypathandidentityfile)
            }
            .onReceive(
                publisherkeypath.debounce(
                    for: .seconds(3),
                    scheduler: DispatchQueue.main
                )
            ) { _ in
                guard selectedconfig != nil else { return }
                parameters.sshkeypath(parameters.sshkeypathandidentityfile)
            }
    }

    var setsshport: some View {
        EditValue(150, "Ssh port", $parameters.sshport)
            .onChange(of: parameters.sshport) {
                publisherport.send(parameters.sshport)
            }
            .onReceive(
                publisherport.debounce(
                    for: .seconds(1),
                    scheduler: DispatchQueue.main
                )
            ) { _ in
                guard selectedconfig != nil else { return }
                parameters.setsshport(parameters.sshport)
            }
    }
}

extension RsyncParametersView {
    func saversyncparameters() {
        updated = true
        if let updatedconfiguration = parameters.updatersyncparameters(),
           let configurations = rsyncUIdata.configurations
        {
            let updateconfigurations =
                UpdateConfigurations(profile: rsyncUIdata.profile,
                                     configurations: configurations)
            updateconfigurations.updateconfiguration(updatedconfiguration, true)
            rsyncUIdata.configurations = updateconfigurations.configurations
            parameters.reset()
            selectedconfig = nil
        }
        Task {
            try await Task.sleep(seconds: 2)
            updated = false
        }
    }
}
