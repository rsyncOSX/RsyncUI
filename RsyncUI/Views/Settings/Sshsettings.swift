//
//  Sshsettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 10/02/2021.
//

import OSLog
import SwiftUI

struct Sshsettings: View {
    @State private var sshsettings = ObservableSSH()
    @State private var localsshkeys: Bool = SshKeys().validatepublickeypresent()
    // Show keys are created
    @State private var showsshkeyiscreated: Bool = false

    var body: some View {
        Form {
            Section(header: Text("Global ssh-keys")
                .font(.title3)
                .fontWeight(.bold)) {
                    VStack(alignment: .leading) {
                        ToggleViewDefault(text: "Public ssh-key is present",
                                          binding: $localsshkeys)
                            .disabled(true)
                    }
                }

            Section(header: Text("Global ssh-keypath and ssh-port")
                .font(.title3)
                .fontWeight(.bold)) {
                    setsshpath(path: $sshsettings.sshkeypathandidentityfile,
                               placeholder: "set SSH keypath and identityfile",
                               selectedValue: sshsettings.sshkeypathandidentityfile)
                    sshportfield(port: $sshsettings.sshportnumber,
                                 placeholder: "set SSH port",
                                 selectedValue: sshsettings.sshportnumber)
                }

            Section(header: Text("Save userconfiguration")
                .font(.title3)
                .fontWeight(.bold)) {
                    ConditionalGlassButton(
                        systemImage: "square.and.arrow.down",
                        text: "Save",
                        helpText: "Save userconfiguration"
                    ) {
                        _ = WriteUserConfigurationJSON(UserConfiguration())
                    }
                }

            if localsshkeys == false {
                Section(header: Text("SSH keys")
                    .font(.title3)
                    .fontWeight(.bold)) {
                        HStack {
                            Button {
                                createKeys()
                            } label: {
                                Image(systemName: "key")
                            }
                            .help("Create keys")
                            .buttonStyle(.borderedProminent)
                        }
                    }
            }

            if showsshkeyiscreated { DismissafterMessageView(dismissafter: 2, mytext: "ssh-key is created, see logfile.") }
        }
        .formStyle(.grouped)
    }
}

extension Sshsettings {
    func createKeys() {
        if SshKeys().createPublicPrivateRSAKeyPair() {
            Task {
                try await Task.sleep(seconds: 1)
                localsshkeys = SshKeys().validatepublickeypresent()
                showsshkeyiscreated = true
            }
        }
    }

    func setsshpath(path: Binding<String>, placeholder: String,
                    selectedValue: String?) -> some View {
        // Determine if the current value should show an error border
        let showErrorBorder: Bool = {
            // Prefer the binding's current value; otherwise, consider the provided selectedValue
            let valueToValidate = path.wrappedValue.isEmpty ? (selectedValue ?? "") : path.wrappedValue
            return !valueToValidate.isEmpty && !isValidSSHKeyPath(valueToValidate)
        }()
        return HStack {
            if sshsettings.sshkeypathandidentityfile.isEmpty {
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
            if sshsettings.sshportnumber.isEmpty {
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
