//
//  RsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2023.
//

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
                    
                    if notifydataisupdated {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.3))
                            Text("Data is changed, please update")
                                .font(.caption2)
                                .foregroundColor(Color.green)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .allowsTightening(false)
                                .minimumScaleFactor(0.5)
                        }
                        .frame(width: 200, height: 30, alignment: .center)
                        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 1))
                        .padding()
                    }

                   
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
                .disabled(parameters.configuration == nil)
        }
        .onChange(of: rsyncUIdata.profile) {
            selectedconfig = nil
            selecteduuids.removeAll()
            parameters.setvalues(selectedconfig)
            backup = false
        }
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .toolbar(content: {
            if selectedconfig != nil {
                ToolbarItem {
                    Button {
                        guard selecteduuids.isEmpty == false else { return }
                        rsyncnavigation.append(ParametersTasks(task: .verify))
                    } label: {
                        Image(systemName: "flag.checkered")
                    }
                    .help("Verify task")
                }
            }

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
        EditValue(300, "ssh-keypath and identityfile",
                  $parameters.sshkeypathandidentityfile)
            .onChange(of: parameters.sshkeypathandidentityfile) {
                Task {
                    try await Task.sleep(seconds: 1)
                    guard selectedconfig != nil else { return }
                    parameters.sshkeypath(parameters.sshkeypathandidentityfile)
                }
            }
    }

    var setsshport: some View {
        EditValue(150, "ssh-port", $parameters.sshport)
            .onChange(of: parameters.sshport) {
                Task {
                    try await Task.sleep(seconds: 1)
                    guard selectedconfig != nil else { return }
                    parameters.setsshport(parameters.sshport)
                }
            }
    }
    
    var notifydataisupdated: Bool {
        guard let selectedconfig else { return false }
        if parameters.parameter8 != (selectedconfig.parameter8 ?? "") ||
            parameters.parameter9 != (selectedconfig.parameter9 ?? "") ||
            parameters.parameter10 != (selectedconfig.parameter10 ?? "") ||
            parameters.parameter11 != (selectedconfig.parameter11 ?? "") ||
            parameters.parameter12 != (selectedconfig.parameter12 ?? "") ||
            parameters.parameter13 != (selectedconfig.parameter13 ?? "") ||
            parameters.parameter14 != (selectedconfig.parameter14 ?? "")
            
        {
            return true
        }
        return false
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
