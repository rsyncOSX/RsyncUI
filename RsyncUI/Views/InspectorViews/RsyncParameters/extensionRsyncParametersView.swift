//
//  extensionRsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 28/12/2025.
//

import SwiftUI

// MARK: - Toolbar

extension RsyncParametersView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem {
            Button {
                presentarguments = true
            } label: {
                Image(systemName: "command")
            }
            .help("Show arguments")
        }

        ToolbarItem {
            ToggleViewToolbar(text: "Parameter",
                              binding: $togglechooseview)
        }

        ToolbarItem {
            Spacer()
        }
    }
}

// MARK: - Business Logic & Actions

extension RsyncParametersView {
    func clearSelection() {
        selectedconfig = nil
        selecteduuids.removeAll()
        parameters.reset()
        backup = false
    }

    func saveRsyncParameters() {
        if let updatedconfiguration = parameters.updatersyncparameters(),
           let configurations = rsyncUIdata.configurations {
            let updateconfigurations =
                UpdateConfigurations(profile: rsyncUIdata.profile,
                                     configurations: configurations)
            updateconfigurations.updateConfiguration(updatedconfiguration, true)
            rsyncUIdata.configurations = updateconfigurations.configurations
            // Reset all after update
            clearSelection()
        }
    }
}

// MARK: - Inspector View

extension RsyncParametersView {
    var inspectorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            addupdateButton

            VStack(alignment: .leading, spacing: 8) {
                EditRsyncParameter(250, $parameters.parameter8)
                    .onChange(of: parameters.parameter8) { parameters.configuration?.parameter8 = parameters.parameter8 }
                EditRsyncParameter(250, $parameters.parameter9)
                    .onChange(of: parameters.parameter9) { parameters.configuration?.parameter9 = parameters.parameter9 }
                EditRsyncParameter(250, $parameters.parameter10)
                    .onChange(of: parameters.parameter10) { parameters.configuration?.parameter10 = parameters.parameter10 }
                EditRsyncParameter(250, $parameters.parameter11)
                    .onChange(of: parameters.parameter11) { parameters.configuration?.parameter11 = parameters.parameter11 }
                EditRsyncParameter(250, $parameters.parameter12)
                    .onChange(of: parameters.parameter12) { parameters.configuration?.parameter12 = parameters.parameter12 }
                EditRsyncParameter(250, $parameters.parameter13)
                    .onChange(of: parameters.parameter13) { parameters.configuration?.parameter13 = parameters.parameter13 }
                EditRsyncParameter(250, $parameters.parameter14)
                    .onChange(of: parameters.parameter14) { parameters.configuration?.parameter14 = parameters.parameter14 }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Task specific SSH parameter").font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    setsshpath
                    setsshport
                }
            }

            let isDeletePresent = selectedconfig?.parameter4 == "--delete"
            let headerText = isDeletePresent ? "Remove --delete parameter" : "Add --delete parameter"
            VStack(alignment: .leading, spacing: 8) {
                Text(headerText)
                    .font(.headline)
                    .foregroundColor(deleteparameterpresent ? Color(.red) : Color(.blue))
                Toggle("--delete", isOn: $parameters.adddelete)
                    .toggleStyle(.switch)
                    .onChange(of: parameters.adddelete) { parameters.adddelete(parameters.adddelete) }
                    .disabled(selecteduuids.isEmpty)
            }

            VStack(alignment: .leading, spacing: 8) {
                Toggle("Backup", isOn: $backup)
                    .toggleStyle(.switch)
                    .onChange(of: backup) {
                        guard !selecteduuids.isEmpty else {
                            backup = false
                            return
                        }
                        parameters.setbackup()
                    }
            }
        }
    }
}

// MARK: - Buttons

extension RsyncParametersView {
    var addupdateButton: some View {
        if notifydataisupdated {
            ConditionalGlassButton(
                systemImage: "arrow.down",
                text: "Update",
                helpText: "Update parameters"
            ) {
                saveRsyncParameters()
                selecteduuids.removeAll()
            }
            .disabled(selectedconfig == nil)
            .padding(.bottom, 10)

        } else {
            ConditionalGlassButton(
                systemImage: "plus",
                text: "Add",
                helpText: "Save parameters"
            ) {
                saveRsyncParameters()
            }
            .disabled(selectedconfig == nil)
            .padding(.bottom, 10)
        }
    }
}

// MARK: - Computed Properties

extension RsyncParametersView {
    var currentFlagStrings: [String] {
        [parameters.parameter8,
         parameters.parameter9,
         parameters.parameter10,
         parameters.parameter11,
         parameters.parameter12,
         parameters.parameter13,
         parameters.parameter14].filter { $0.isEmpty == false }
    }
}

// MARK: - Task List View

extension RsyncParametersView {
    var taskListView: some View {
        ListofTasksAddView(rsyncUIdata: rsyncUIdata, selecteduuids: $selecteduuids)
            .onChange(of: selecteduuids) { handleSelectionChange() }
    }
}

// MARK: - Event Handlers

extension RsyncParametersView {
    func handleSelectionChange() {
        showhelp = false
        if let configurations = rsyncUIdata.configurations {
            if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                selectedconfig = configurations[index]
                parameters.setvalues(configurations[index])
                if configurations[index].parameter12 != "--backup" {
                    backup = false
                }
                showinspector = true
            } else {
                selectedconfig = nil
                parameters.setvalues(selectedconfig)
                backup = false
                showinspector = false
            }
        }
    }
}

// MARK: - SSH Configuration Fields

extension RsyncParametersView {
    var setsshpath: some View {
        EditValueErrorScheme(300, "ssh-keypath and identityfile",
                             $parameters.sshkeypathandidentityfile,
                             parameters.sshkeypath(parameters.sshkeypathandidentityfile))
    }

    var setsshport: some View {
        EditValueErrorScheme(150, "ssh-port", $parameters.sshport,
                             parameters.setsshport(parameters.sshport))
    }
}

// MARK: - State Properties

extension RsyncParametersView {
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
}

// MARK: - Help View

extension RsyncParametersView {
    var helpSheetView: some View {
        switch parameters.whichhelptext {
        case 1: HelpView(text: parameters.helptext1, add: false, deleteparameterpresent: false)
        case 2: HelpView(text: parameters.helptext2, add: false, deleteparameterpresent: false)
        default: HelpView(text: parameters.helptext1, add: false, deleteparameterpresent: false)
        }
    }
}
