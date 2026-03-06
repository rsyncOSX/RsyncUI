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

// MARK: - Event Handlers

extension RsyncParametersView {
    func handleSelectionChange() {
        if let configurations = rsyncUIdata.configurations {
            guard selecteduuids.count == 1 else {
                return
            }
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
        var sshport = ""
        var sshkeypathandidentityfile = ""

        if let configsshport = selectedconfig?.sshport, configsshport != -1 {
            sshport = String(configsshport)
        }
        if let configurationsshcreatekey = selectedconfig?.sshkeypathandidentityfile {
            sshkeypathandidentityfile = configurationsshcreatekey
        }
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
            parameters.sshport != String(sshport) ||
            parameters.sshkeypathandidentityfile != sshkeypathandidentityfile {
            return true
        }
        return false
    }

    var deleteparameterpresent: Bool {
        rsyncUIdata.configurations?.contains(where: { $0.parameter4?.isEmpty == false }) ?? false
    }
}
