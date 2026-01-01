//
//  extensionRsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 28/12/2025.
//

import SwiftUI

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
                EditRsyncParameter(350, $parameters.parameter8)
                    .onChange(of: parameters.parameter8) { parameters.configuration?.parameter8 = parameters.parameter8 }
                EditRsyncParameter(350, $parameters.parameter9)
                    .onChange(of: parameters.parameter9) { parameters.configuration?.parameter9 = parameters.parameter9 }
                EditRsyncParameter(350, $parameters.parameter10)
                    .onChange(of: parameters.parameter10) { parameters.configuration?.parameter10 = parameters.parameter10 }
                EditRsyncParameter(350, $parameters.parameter11)
                    .onChange(of: parameters.parameter11) { parameters.configuration?.parameter11 = parameters.parameter11 }
                EditRsyncParameter(350, $parameters.parameter12)
                    .onChange(of: parameters.parameter12) { parameters.configuration?.parameter12 = parameters.parameter12 }
                EditRsyncParameter(350, $parameters.parameter13)
                    .onChange(of: parameters.parameter13) { parameters.configuration?.parameter13 = parameters.parameter13 }
                EditRsyncParameter(350, $parameters.parameter14)
                    .onChange(of: parameters.parameter14) { parameters.configuration?.parameter14 = parameters.parameter14 }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Task specific SSH parameter").font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    setsshpath(path: $parameters.sshkeypathandidentityfile,
                               placeholder: "set SSH keypath and identityfile",
                               selectedValue: parameters.sshkeypathandidentityfile)
                    sshportfield(port: $parameters.sshport,
                                 placeholder: "set SSH port",
                                 selectedValue: parameters.sshport)
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

// MARK: - Event Handlers

extension RsyncParametersView {
    func handleSelectionChange() {
        if let configurations = rsyncUIdata.configurations {
            guard selecteduuids.count == 1 else {
                showinspector = false
                return
            }
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
    func setsshpath(path: Binding<String>, placeholder: String,
                    selectedValue: String?) -> some View {
        // Determine if the current value should show an error border
        let showErrorBorder: Bool = {
            // Prefer the binding's current value; otherwise, consider the provided selectedValue
            let valueToValidate = path.wrappedValue.isEmpty ? (selectedValue ?? "") : path.wrappedValue
            return !valueToValidate.isEmpty && !isValidSSHKeyPath(valueToValidate)
        }()
        return HStack {
            if parameters.sshkeypathandidentityfile.isEmpty {
                EditValueScheme(300, placeholder, path)
                    .textContentType(.none)
                    .submitLabel(.continue)
                    .border(showErrorBorder ? Color.red : Color.clear, width: 2)
            } else {
                EditValueScheme(300, nil, path)
                    .textContentType(.none)
                    .submitLabel(.continue)
                    .onAppear { if let value = selectedValue { path.wrappedValue = value } }
                    .border(showErrorBorder ? Color.red : Color.clear, width: 2)
            }
        }
    }

    func sshportfield(port: Binding<String>, placeholder: String,
                      selectedValue: String?) -> some View {
        // Determine if the current value should show an error border
        let showErrorBorder: Bool = {
            // Prefer the binding's current value; otherwise, consider the provided selectedValue
            let valueToValidate = port.wrappedValue.isEmpty ? (selectedValue ?? "") : port.wrappedValue
            return !valueToValidate.isEmpty && !isValidSSHPort(valueToValidate)
        }()

        return HStack {
            if parameters.sshport.isEmpty {
                EditValueScheme(150, placeholder, port)
                    .textContentType(.none)
                    .submitLabel(.continue)
                    .border(showErrorBorder ? Color.red : Color.clear, width: 2)
            } else {
                EditValueScheme(150, nil, port)
                    .textContentType(.none)
                    .submitLabel(.continue)
                    .onAppear { if let value = selectedValue { port.wrappedValue = value } }
                    .border(showErrorBorder ? Color.red : Color.clear, width: 2)
            }
        }
    }

    func isValidSSHPort(_ port: String) -> Bool {
        guard let port = Int(port.trimmingCharacters(in: .whitespacesAndNewlines)) else { return false }
        return (22 ... 65535).contains(port)
    }

    func isValidSSHKeyPath(_ keyPath: String) -> Bool {
        // Check starts with tilde
        guard keyPath.hasPrefix("~") else { return false }

        // Check contains two or more slashes
        let slashCount = keyPath.filter { $0 == "/" }.count
        guard slashCount >= 2 else { return false }

        // Expand to full path
        let expandedPath = (keyPath as NSString).expandingTildeInPath

        // Check existence
        return FileManager.default.fileExists(atPath: expandedPath)
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
