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
                    .onAppear { if let id = newdata.selectedconfig?.backupID { newdata.backupID = id } }
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
                         placeholder: "Source folder (required):",
                         focus: .localcatalogField,
                         selectedValue: newdata.selectedconfig?.localCatalog)
            catalogField(catalog: $newdata.remotecatalog,
                         placeholder: "Destination folder (required):",
                         focus: .remotecatalogField,
                         selectedValue: newdata.selectedconfig?.offsiteCatalog,
                         showErrorBorder: !newdata.localcatalog.isEmpty && newdata.remotecatalog.isEmpty ||
                             newdata.localcatalog.isEmpty && !newdata.remotecatalog.isEmpty)
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
                         placeholder: "Source Folder (required):",
                         focus: .remotecatalogField,
                         selectedValue: newdata.selectedconfig?.offsiteCatalog)
            catalogField(catalog: $newdata.localcatalog,
                         placeholder: "Remote Folder (required):",
                         focus: .localcatalogField,
                         selectedValue: newdata.selectedconfig?.localCatalog,
                         showErrorBorder: !newdata.localcatalog.isEmpty && newdata.remotecatalog.isEmpty ||
                             newdata.localcatalog.isEmpty && !newdata.remotecatalog.isEmpty)
        }
    }

    func settrailingSlash(for value: Binding<String>)  {
        var text = value.wrappedValue
        guard text.isEmpty == false else { return }
        
        if trailingslashoption && !text.isEmpty {
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
    
    func catalogField(catalog: Binding<String>, placeholder: String,
                      focus: AddConfigurationField, selectedValue: String?,
                      showErrorBorder: Bool = false) -> some View {
        HStack {
            if newdata.selectedconfig == nil {
                TextField(placeholder, text: catalog)
                    .focused($focusField, equals: focus)
                    .textContentType(.none).submitLabel(.continue)
                    .border(showErrorBorder ? Color.red : Color.clear, width: 2)
            } else {
                TextField(placeholder, text: catalog)
                    .focused($focusField, equals: focus)
                    .textContentType(.none).submitLabel(.continue)
                    .onAppear { if let value = selectedValue { catalog.wrappedValue = value } }
                    .border(showErrorBorder ? Color.red : Color.clear, width: 2)
            }
            OpencatalogView(selecteditem: catalog, catalogs: true)
        }
    }

    var remoteuserandserver: some View {
        Section("Remote") {
            remoteField(
                value: $newdata.remoteuser,
                placeholder: "Remote user:",
                focus: .remoteuserField,
                selectedValue: newdata.selectedconfig?.offsiteUsername,
                showErrorBorder: newdata.remoteuser.isEmpty && !newdata.remoteserver.isEmpty
            )
            remoteField(
                value: $newdata.remoteserver,
                placeholder: "Remote server:",
                focus: .remoteserverField,
                selectedValue: newdata.selectedconfig?.offsiteServer,
                submitLabel: .return,
                showErrorBorder: !newdata.remoteuser.isEmpty && newdata.remoteserver.isEmpty
            )
        }
    }

    func remoteField(value: Binding<String>, placeholder: String, focus: AddConfigurationField,
                     selectedValue: String?, submitLabel: SubmitLabel = .continue,
                     showErrorBorder: Bool = false) -> some View {
        Group {
            if newdata.selectedconfig == nil {
                TextField(placeholder, text: value)
                    .focused($focusField, equals: focus)
                    .textContentType(.none).submitLabel(submitLabel)
                    .border(showErrorBorder ? Color.red : Color.clear, width: 1)
            } else {
                TextField(placeholder, text: value)
                    .focused($focusField, equals: focus)
                    .textContentType(.none).submitLabel(submitLabel)
                    .onAppear { if let val = selectedValue { value.wrappedValue = val } }
                    .border(showErrorBorder ? Color.red : Color.clear, width: 1)
            }
        }
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
