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
    @ViewBuilder
    func SynchronizeIDSection() -> some View {
        Section("Synchronize ID") {
            TextField("Synchronize ID", text: $newdata.backupID)
                .focused($focusField, equals: .synchronizeIDField)
                .textContentType(.none).submitLabel(.continue)
                .onAppear { if newdata.selectedconfig == nil, let id = newdata.selectedconfig?.backupID { newdata.backupID = id } }
        }
    }

    @ViewBuilder
    func SnapshotNumberSection() -> some View {
        Section("Snapshot Number") {
            HStack {
                Toggle("Change Snapshot Number", isOn: $changesnapshotnum)
                    .toggleStyle(.switch)
                    .labelsHidden()
                TextField("Change Snapshot Number", text: $newdata.snapshotnum)
                    .lineLimit(1)
                    .focused($focusField, equals: .snapshotnumField)
                    .textContentType(.none).submitLabel(.return)
                    .disabled(!changesnapshotnum)
            }
        }
    }

    @ViewBuilder
    func FoldersSection() -> some View {
        Section("Folders") {
            CatalogField(catalog: $newdata.localcatalog,
                         placeholder: "Source Folder (required)",
                         focus: .localcatalogField,
                         selectedValue: newdata.selectedconfig?.localCatalog)
            CatalogField(catalog: $newdata.remotecatalog,
                         placeholder: "Destination Folder (required)",
                         focus: .remotecatalogField,
                         selectedValue: newdata.selectedconfig?.offsiteCatalog,
                         showErrorBorder: !newdata.localcatalog.isEmpty && newdata.remotecatalog.isEmpty ||
                             newdata.localcatalog.isEmpty && !newdata.remotecatalog.isEmpty)
        }
    }

    @ViewBuilder
    func SyncRemoteFoldersSection() -> some View {
        Section("Folders") {
            CatalogField(catalog: $newdata.remotecatalog,
                         placeholder: "Source Folder (required)",
                         focus: .remotecatalogField,
                         selectedValue: newdata.selectedconfig?.offsiteCatalog)
            CatalogField(catalog: $newdata.localcatalog,
                         placeholder: "Remote Folder (required)",
                         focus: .localcatalogField,
                         selectedValue: newdata.selectedconfig?.localCatalog,
                         showErrorBorder: !newdata.localcatalog.isEmpty && newdata.remotecatalog.isEmpty ||
                             newdata.localcatalog.isEmpty && !newdata.remotecatalog.isEmpty)
        }
    }

    @ViewBuilder
    func CatalogField(catalog: Binding<String>, placeholder: String,
                      focus: AddConfigurationField, selectedValue: String?,
                      showErrorBorder: Bool = false) -> some View {
        HStack {
            TextField(placeholder, text: catalog)
                .focused($focusField, equals: focus)
                .textContentType(.none).submitLabel(.continue)
                .border(showErrorBorder ? Color.red : Color.clear, width: 2)
                .onAppear {
                    if newdata.selectedconfig != nil, let value = selectedValue { catalog.wrappedValue = value }
                }
            OpencatalogView(selecteditem: catalog, catalogs: true)
        }
    }

    @ViewBuilder
    func RemoteSection() -> some View {
        Section("Remote") {
            RemoteField(
                value: $newdata.remoteuser,
                placeholder: "Remote User",
                focus: .remoteuserField,
                selectedValue: newdata.selectedconfig?.offsiteUsername,
                showErrorBorder: newdata.remoteuser.isEmpty && !newdata.remoteserver.isEmpty
            )
            RemoteField(
                value: $newdata.remoteserver,
                placeholder: "Remote Server",
                focus: .remoteserverField,
                selectedValue: newdata.selectedconfig?.offsiteServer,
                submitLabel: .return,
                showErrorBorder: !newdata.remoteuser.isEmpty && newdata.remoteserver.isEmpty
            )
        }
    }

    @ViewBuilder
    func RemoteField(value: Binding<String>, placeholder: String, focus: AddConfigurationField,
                     selectedValue: String?, submitLabel: SubmitLabel = .continue,
                     showErrorBorder: Bool = false) -> some View {
            TextField(placeholder, text: value)
                .focused($focusField, equals: focus)
                .textContentType(.none).submitLabel(submitLabel)
                .onAppear { if newdata.selectedconfig == nil, let val = selectedValue { value.wrappedValue = val } }
                .border(showErrorBorder ? Color.red : Color.clear, width: 2)
    }

    @ViewBuilder
    func TrailingSlashPicker() -> some View {
        Picker("Trailing /", selection: $newdata.trailingslashoptions) {
            ForEach(TrailingSlash.allCases) { Text($0.description).tag($0) }
        }
        .pickerStyle(.menu)
        .onChange(of: newdata.trailingslashoptions) {
            UserDefaults.standard.set(newdata.trailingslashoptions.rawValue, forKey: "trailingslashoptions")
        }
        .onAppear { loadTrailingSlashPreference() }
    }

    @ViewBuilder
    func TaskTypePicker() -> some View {
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
