//
//  RsyncDefaultParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2023.
//

import SwiftUI

struct RsyncDefaultParametersView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var path: [ParametersTasks]

    @State private var parameters = ObservableParametersDefault()
    @State private var selectedrsynccommand = RsyncCommand.synchronize_data
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Section(header: headerremove) {
                        VStack(alignment: .leading) {
                            ToggleViewDefault(text: "--compress", binding: $parameters.removecompress)
                                .onChange(of: parameters.removecompress) {
                                    parameters.deletecompress(parameters.removecompress)
                                }
                                .disabled(selecteduuids.isEmpty == true)
                            ToggleViewDefault(text: "--delete", binding: $parameters.removedelete)
                                .onChange(of: parameters.removedelete) {
                                    parameters.deletedelete(parameters.removedelete)
                                }
                                .disabled(selecteduuids.isEmpty == true)
                        }
                    }

                    Section(header: headerdaemon) {
                        ToggleViewDefault(text: "daemon", binding: $parameters.daemon)
                            .disabled(selecteduuids.isEmpty == true)
                    }

                    Spacer()
                }

                ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                            profile: rsyncUIdata.profile,
                                            configurations: rsyncUIdata.configurations)
                    .frame(maxWidth: .infinity)
                    .onChange(of: selecteduuids) {
                        if let configurations = rsyncUIdata.configurations {
                            if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                                parameters.setvalues(configurations[index])
                            } else {
                                parameters.setvalues(nil)
                            }
                        }
                    }
                    .onChange(of: rsyncUIdata.profile) {
                        parameters.setvalues(nil)
                        selecteduuids.removeAll()
                    }
            }

            Spacer()

            VStack(alignment: .leading) {
                Text("Select a task")

                RsyncCommandView(config: $parameters.configuration, selectedrsynccommand: $selectedrsynccommand)
                    .disabled(parameters.configuration == nil)
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    saversyncparameters()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(.blue))
                }
                .help("Update task")
            }
        }
        .padding()
    }

    // Header remove
    var headerremove: some View {
        Text("Remove default rsync parameters")
    }

    // Daemon header
    var headerdaemon: some View {
        Text("Enable rsync daemon")
    }
}

extension RsyncDefaultParametersView {
    func saversyncparameters() {
        if let updatedconfiguration = parameters.updatersyncparameters(),
           let configurations = rsyncUIdata.configurations
        {
            let updateconfigurations =
                UpdateConfigurations(profile: rsyncUIdata.profile,
                                     configurations: configurations)
            updateconfigurations.updateconfiguration(updatedconfiguration, true)
            rsyncUIdata.configurations = updateconfigurations.configurations
            parameters.reset()
        }
        Task {
            try await Task.sleep(seconds: 2)
            path.removeAll()
        }
    }
}
