//
//  RsyncDefaultParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2023.
//

import SwiftUI

struct RsyncDefaultParametersView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var reload: Bool
    @Binding var path: [ParametersTasks]

    @State private var parameters = ObservableParametersDefault()
    @State private var selectedconfig: Configuration?
    @State private var selectedrsynccommand = RsyncCommand.synchronize
    @State private var valueselectedrow: String = ""
    @State private var selecteduuids = Set<Configuration.ID>()

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Section(header: headerremove) {
                        VStack(alignment: .leading) {
                            ToggleViewDefault("-e ssh", $parameters.removessh)
                                .onChange(of: parameters.removessh) {
                                    parameters.deletessh(parameters.removessh)
                                }
                            ToggleViewDefault("--compress", $parameters.removecompress)
                                .onChange(of: parameters.removecompress) {
                                    parameters.deletecompress(parameters.removecompress)
                                }
                            ToggleViewDefault("--delete", $parameters.removedelete)
                                .onChange(of: parameters.removedelete) {
                                    parameters.deletedelete(parameters.removedelete)
                                }
                        }
                    }

                    Section(header: headerdaemon) {
                        ToggleViewDefault("daemon", $parameters.daemon)
                    }

                    Spacer()
                }

                ListofTasksLightView(rsyncUIdata: rsyncUIdata, selecteduuids: $selecteduuids)
                    .frame(maxWidth: .infinity)
                    .onChange(of: selecteduuids) {
                        let selected = rsyncUIdata.configurations?.filter { config in
                            selecteduuids.contains(config.id)
                        }
                        if (selected?.count ?? 0) == 1 {
                            if let config = selected {
                                selectedconfig = config[0]
                                parameters.setvalues(selectedconfig)
                            }
                        } else {
                            selectedconfig = nil
                            parameters.setvalues(selectedconfig)
                        }
                    }
            }

            Spacer()

            RsyncCommandView(config: $parameters.configuration, selectedrsynccommand: $selectedrsynccommand)
        }
        .toolbar {
            ToolbarItem {
                Button {
                    saversyncparameters()
                    path.removeAll()
                } label: {
                    Image(systemName: "square.and.arrow.down.fill")
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
        if let configuration = parameters.updatersyncparameters() {
            let updateconfiguration =
                UpdateConfigurations(profile: rsyncUIdata.profile,
                                     configurations: rsyncUIdata.getallconfigurations())
            updateconfiguration.updateconfiguration(configuration, true)
        }
        parameters.reset()
        selectedconfig = nil
        reload = true
    }
}
