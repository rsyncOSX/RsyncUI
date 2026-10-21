//
//  extensionAddTaskView+FormFields.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 13/12/2025.
//
import OSLog
import SwiftUI

// MARK: - Form Field Sections

extension AddTaskView {
    var synchronizeID: some View {
        Section("Synchronize ID") {
            if newdata.selectedconfig == nil {
                TextField("Synchronize ID:", text: $newdata.backupID)
                    .focused($focusField, equals: .synchronizeIDField)
                    .textContentType(.none).submitLabel(.continue)
            } else {
                TextField("Synchronize ID:", text: $newdata.backupID)
                    .focused($focusField, equals: .synchronizeIDField)
                    .textContentType(.none).submitLabel(.continue)
                    .onAppear {
                        if let id = newdata.selectedconfig?.backupID {
                            newdata.backupID = id
                        }
                    }
            }
        }
    }

    var snapshotnum: some View {
        Section("Snapshot Number") {
            EditValueScheme(400, nil, $newdata.snapshotnum)
                .focused($focusField, equals: .snapshotnumField)
                .textContentType(.none).submitLabel(.return)
                .disabled(!changesnapshotnum)
            ToggleViewDefault(text: "Change snapshotnumber", binding: $changesnapshotnum)
        }
    }

    var localandremotecatalog: some View {
        Section("Folders") {
            Toggle("Trailing Slash on Source folder", isOn: $trailingslashoption)
                .onChange(of: trailingslashoption) {
                    UserDefaults.standard.set(trailingslashoption, forKey: "trailingslashoptions")
                    settrailingSlash(for: $newdata.localcatalog)
                }
                .onAppear {
                    let storedValue = UserDefaults.standard.object(forKey: "trailingslashoptions")
                    if let trailingSlash = storedValue as? Bool {
                        trailingslashoption = trailingSlash
                    } else if let legacyValue = storedValue as? String {
                        trailingslashoption = legacyValue == "add"
                        UserDefaults.standard.set(trailingslashoption, forKey: "trailingslashoptions")
                    }
                }

            catalogField(catalog: $newdata.localcatalog,
                         placeholder: "Source folder:",
                         hint: "Choose a source folder.",
                         focus: .localcatalogField,
                         selectedValue: newdata.selectedconfig?.localCatalog)
            catalogField(catalog: $newdata.remotecatalog,
                         placeholder: "Destination folder:",
                         hint: "Choose a destination folder.",
                         focus: .remotecatalogField,
                         selectedValue: newdata.selectedconfig?.offsiteCatalog)
        }
    }

    var localandremotecatalogsyncremote: some View {
        Section("Folders") {
            Toggle("Trailing Slash on Source folder", isOn: $trailingslashoption)
                .onChange(of: trailingslashoption) {
                    UserDefaults.standard.set(trailingslashoption, forKey: "trailingslashoptions")
                    settrailingSlash(for: $newdata.remotecatalog)
                }
                .onAppear {
                    let storedValue = UserDefaults.standard.object(forKey: "trailingslashoptions")
                    if let trailingSlash = storedValue as? Bool {
                        trailingslashoption = trailingSlash
                    } else if let legacyValue = storedValue as? String {
                        trailingslashoption = legacyValue == "add"
                        UserDefaults.standard.set(trailingslashoption, forKey: "trailingslashoptions")
                    }
                }

            catalogField(catalog: $newdata.remotecatalog,
                         placeholder: "Source folder:",
                         hint: "Enter the remote source folder.",
                         focus: .remotecatalogField,
                         selectedValue: newdata.selectedconfig?.offsiteCatalog)
            catalogField(catalog: $newdata.localcatalog,
                         placeholder: "Destination folder:",
                         hint: "Choose a local destination folder.",
                         focus: .localcatalogField,
                         selectedValue: newdata.selectedconfig?.localCatalog)
        }
    }

    func settrailingSlash(for value: Binding<String>) {
        var text = value.wrappedValue
        guard text.isEmpty == false else { return }

        if trailingslashoption, !text.isEmpty {
            if !text.hasSuffix("/") {
                text += "/"
            }
        } else {
            if text.hasSuffix("/") {
                text.removeLast()
            }
        }

        value.wrappedValue = text
    }

    func catalogField(catalog: Binding<String>, placeholder: LocalizedStringKey,
                      hint: LocalizedStringKey,
                      focus: AddConfigurationField, selectedValue: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                TextField(placeholder, text: catalog)
                    .focused($focusField, equals: focus)
                    .textContentType(.none).submitLabel(.continue)
                    .onAppear {
                        if newdata.selectedconfig != nil, let value = selectedValue {
                            catalog.wrappedValue = value
                        }
                    }
                if catalog.wrappedValue.isEmpty {
                    RequiredFieldMarker()
                }
                OpencatalogView(selecteditem: catalog, catalogs: true)
            }
            if catalog.wrappedValue.isEmpty {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var remoteuserandserver: some View {
        Section("Remote") {
            remoteField(
                value: $newdata.remoteuser,
                focus: .remoteuserField,
                selectedValue: newdata.selectedconfig?.offsiteUsername,
                isRequired: remoteUserIsMissing,
                hint: newdata.selectedrsynccommand == .syncremote
                    ? "Enter the user for the remote source."
                    : "Enter a remote user, or clear Remote server for a local task."
            )
            remoteField(
                value: $newdata.remoteserver,
                focus: .remoteserverField,
                selectedValue: newdata.selectedconfig?.offsiteServer,
                isRequired: remoteServerIsMissing,
                hint: newdata.selectedrsynccommand == .syncremote
                    ? "Enter the server for the remote source."
                    : "Enter a remote server, or clear Remote user for a local task."
            )
        }
    }

    func remoteField(value: Binding<String>, focus: AddConfigurationField,
                     selectedValue: String?,
                     isRequired: Bool, hint: LocalizedStringKey) -> some View {
        let title: LocalizedStringKey = focus == .remoteserverField ? "Remote server:" : "Remote user:"
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                TextField(title, text: value)
                    .focused($focusField, equals: focus)
                    .textContentType(.none).submitLabel(focus == .remoteserverField ? .return : .continue)
                    .onAppear {
                        if newdata.selectedconfig != nil, let val = selectedValue {
                            value.wrappedValue = val
                        }
                    }
                if isRequired {
                    RequiredFieldMarker()
                }
            }
            if isRequired {
                Label {
                    Text(hint)
                } icon: {
                    Image(systemName: "info.circle")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    var remoteUserIsMissing: Bool {
        newdata.remoteuser.isEmpty &&
            (!newdata.remoteserver.isEmpty || newdata.selectedrsynccommand == .syncremote)
    }

    var remoteServerIsMissing: Bool {
        newdata.remoteserver.isEmpty &&
            (!newdata.remoteuser.isEmpty || newdata.selectedrsynccommand == .syncremote)
    }

    /// Check completeness without running the connection checks in the full validator.
    var requiredFieldsAreComplete: Bool {
        !newdata.localcatalog.replacingOccurrences(of: "\"", with: "").isEmpty &&
            !newdata.remotecatalog.replacingOccurrences(of: "\"", with: "").isEmpty &&
            !remoteUserIsMissing && !remoteServerIsMissing
    }

    var pickerselecttypeoftask: some View {
        Picker("Action", selection: $newdata.selectedrsynccommand) {
            ForEach(TypeofTask.allCases) { Text($0.description).tag($0) }
        }
        .pickerStyle(.menu)
        .onChange(of: newdata.selectedrsynccommand) {
            UserDefaults.standard.set(newdata.selectedrsynccommand.rawValue, forKey: "selectedrsynccommand")
        }
        .onAppear { loadRsyncCommandPreference() }
    }
}

private struct RequiredFieldMarker: View {
    var body: some View {
        Text("Required")
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize()
    }
}
