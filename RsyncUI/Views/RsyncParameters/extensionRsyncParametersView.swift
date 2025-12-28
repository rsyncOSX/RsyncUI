//
//  extensionRsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 28/12/2025.
//

import SwiftUI

extension RsyncParametersView {
    func saveRsyncParameters() {
        if let updatedconfiguration = parameters.updatersyncparameters(),
           let configurations = rsyncUIdata.configurations {
            let updateconfigurations =
                UpdateConfigurations(profile: rsyncUIdata.profile,
                                     configurations: configurations)
            updateconfigurations.updateConfiguration(updatedconfiguration, true)
            rsyncUIdata.configurations = updateconfigurations.configurations
            parameters.reset()
            selectedconfig = nil
        }
    }

    var inspectorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Inspector").font(.title3).fontWeight(.bold)
                Spacer()
                Button {
                    selectedconfig = nil
                    selecteduuids.removeAll()
                    parameters.reset()
                    backup = false
                    parameters.showdetails = false
                } label: { Image(systemName: "xmark.circle") }
                    .buttonStyle(.borderless)
                    .help("Clear selection")
            }

            if let selectedconfig {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedconfig.backupID).font(.headline)
                    Text(selectedconfig.task).font(.subheadline).foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Parameters 8–14").font(.headline)
                    EditRsyncParameter(380, $parameters.parameter8)
                        .onChange(of: parameters.parameter8) { parameters.configuration?.parameter8 = parameters.parameter8 }
                    EditRsyncParameter(380, $parameters.parameter9)
                        .onChange(of: parameters.parameter9) { parameters.configuration?.parameter9 = parameters.parameter9 }
                    EditRsyncParameter(380, $parameters.parameter10)
                        .onChange(of: parameters.parameter10) { parameters.configuration?.parameter10 = parameters.parameter10 }
                    EditRsyncParameter(380, $parameters.parameter11)
                        .onChange(of: parameters.parameter11) { parameters.configuration?.parameter11 = parameters.parameter11 }
                    EditRsyncParameter(380, $parameters.parameter12)
                        .onChange(of: parameters.parameter12) { parameters.configuration?.parameter12 = parameters.parameter12 }
                    EditRsyncParameter(380, $parameters.parameter13)
                        .onChange(of: parameters.parameter13) { parameters.configuration?.parameter13 = parameters.parameter13 }
                    EditRsyncParameter(380, $parameters.parameter14)
                        .onChange(of: parameters.parameter14) { parameters.configuration?.parameter14 = parameters.parameter14 }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Task specific SSH parameter").font(.headline)
                    HStack {
                        setsshpath
                        setsshport
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Options").font(.headline)
                    Toggle("Backup", isOn: $backup)
                        .toggleStyle(.switch)
                        .onChange(of: backup) {
                            guard selectedconfig != nil else {
                                backup = false
                                return
                            }
                            parameters.setbackup()
                        }
                    Toggle("Show command", isOn: $parameters.showdetails)
                        .toggleStyle(.switch)
                }

                Divider()

                let isDeletePresent = selectedconfig.parameter4 == "--delete"
                let headerText = isDeletePresent ? "Remove --delete parameter" : "Add --delete parameter"
                VStack(alignment: .leading, spacing: 8) {
                    Text(headerText)
                        .font(.headline)
                        .foregroundColor(deleteparameterpresent ? Color(.red) : Color(.blue))
                    Toggle("--delete", isOn: $parameters.adddelete)
                        .toggleStyle(.switch)
                        .onChange(of: parameters.adddelete) { parameters.adddelete(parameters.adddelete) }
                        .disabled(selecteduuids.isEmpty)
                    HStack(spacing: 6) {
                        if deleteparameterpresent {
                            Text("If red Synchronize ID click")
                            Button {
                                parameters.whichhelptext = 1
                                showhelp = true
                            } label: { Image(systemName: "questionmark.circle") }
                                .buttonStyle(HelpButtonStyle(redorwhitebutton: deleteparameterpresent))
                            Text("for more information")
                        } else {
                            Text("To add --delete click")
                            Button {
                                parameters.whichhelptext = 2
                                showhelp = true
                            } label: { Image(systemName: "questionmark.circle") }
                                .buttonStyle(HelpButtonStyle(redorwhitebutton: deleteparameterpresent))
                            Text("for more information")
                        }
                    }
                }

                if parameters.showdetails {
                    RsyncCommandView(config: selectedconfig)
                        .frame(maxWidth: .infinity)
                }
            } else {
                Text("Select a task from the list to view and inspect.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: 420)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var currentFlagStrings: [String] {
        [parameters.parameter8,
         parameters.parameter9,
         parameters.parameter10,
         parameters.parameter11,
         parameters.parameter12,
         parameters.parameter13,
         parameters.parameter14].filter { $0.isEmpty == false }
    }
    
    var taskListView: some View {
        ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                    configurations: rsyncUIdata.configurations)
            .frame(maxWidth: .infinity, maxHeight: 330)
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
                        parameters.showdetails = false
                    }
                }
            }
    }
    
    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear {
                focusaborttask = false
                abort()
            }
    }

    var setsshpath: some View {
        EditValueErrorScheme(300, "ssh-keypath and identityfile",
                             $parameters.sshkeypathandidentityfile,
                             parameters.sshkeypath(parameters.sshkeypathandidentityfile))
    }

    var setsshport: some View {
        EditValueErrorScheme(150, "ssh-port", $parameters.sshport,
                             parameters.setsshport(parameters.sshport))
    }

    var notifydataisupdated: Bool {
        guard let selectedconfig else { return false }
        if parameters.parameter8 != (selectedconfig.parameter8 ?? "") ||
            parameters.parameter9 != (selectedconfig.parameter9 ?? "") ||
            parameters.parameter10 != (selectedconfig.parameter10 ?? "") ||
            parameters.parameter11 != (selectedconfig.parameter11 ?? "") ||
            parameters.parameter12 != (selectedconfig.parameter12 ?? "") ||
            parameters.parameter13 != (selectedconfig.parameter13 ?? "") ||
            parameters.parameter14 != (selectedconfig.parameter14 ?? "") ||
            parameters.parameter14 != (selectedconfig.parameter14 ?? "") ||
            parameters.adddelete == (selectedconfig.parameter4 == nil) ||
            // parameters.sshport != String(selectedconfig.sshport ?? -1) ||
            parameters.sshkeypathandidentityfile != (selectedconfig.sshkeypathandidentityfile ?? "") {
            return true
        }
        return false
    }

    var deleteparameterpresent: Bool {
        let parameter = rsyncUIdata.configurations?.filter { $0.parameter4?.isEmpty == false }
        return parameter?.count ?? 0 > 0
    }

    var helpSection: some View {
        Group {
            if deleteparameterpresent {
                HStack {
                    Text("If \(Text("red Synchronize ID").foregroundColor(.red)) click")
                    Button { parameters.whichhelptext = 1; showhelp.toggle() }
                        label: { Image(systemName: "questionmark.circle") }
                        .buttonStyle(HelpButtonStyle(redorwhitebutton: deleteparameterpresent))
                    Text("for more information")
                }
            } else {
                HStack {
                    Text("To add --delete click")
                    Button { parameters.whichhelptext = 2; showhelp.toggle() }
                        label: { Image(systemName: "questionmark.circle") }
                        .buttonStyle(HelpButtonStyle(redorwhitebutton: deleteparameterpresent))
                    Text("for more information")
                }
            }
        }
        .padding(.bottom, 10)
    }
    
    @ViewBuilder
    var helpSheetView: some View {
        switch parameters.whichhelptext {
        case 1: HelpView(text: parameters.helptext1, add: false, deleteparameterpresent: false)
        case 2: HelpView(text: parameters.helptext2, add: false, deleteparameterpresent: false)
        default: HelpView(text: parameters.helptext1, add: false, deleteparameterpresent: false)
        }
    }
}
