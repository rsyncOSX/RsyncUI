//
//  TaskForm.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 13/12/2025.
//
import OSLog
import SwiftUI

enum TaskFormMode {
    case add
    case update
}

struct TaskForm: View {
    let mode: TaskFormMode

    @FocusState var focusField: AddConfigurationField?

    @Binding var newdata: ObservableAddConfigurations
    @Binding var selectedconfig: SynchronizeConfiguration?
    @Binding var changesnapshotnum: Bool
    @Binding var stringestimate: String

    var onUpdate: (() -> Void)?

    func loadTrailingSlashPreference() {
        if let value = UserDefaults.standard.value(forKey: "trailingslashoptions") as? String {
            newdata.trailingslashoptions = TrailingSlash(rawValue: value) ?? .add
        }
    }

    func loadRsyncCommandPreference() {
        if let value = UserDefaults.standard.value(forKey: "selectedrsynccommand") as? String {
            newdata.selectedrsynccommand = TypeofTask(rawValue: value) ?? .synchronize
        }
    }

    var showSnapshot: Bool {
        selectedconfig?.task == SharedReference.shared.snapshot
    }

    var synchronizeID: some View {
        Section("Synchronize ID") {
            if newdata.selectedconfig == nil {
                TextField("Synchronize ID", text: $newdata.backupID)
                    .focused($focusField, equals: .synchronizeIDField)
                    .textContentType(.none).submitLabel(.continue)
            } else {
                TextField("Synchronize ID", text: $newdata.backupID)
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
            catalogField(catalog: $newdata.localcatalog,
                         placeholder: "Source folder (required)",
                         focus: .localcatalogField,
                         selectedValue: newdata.selectedconfig?.localCatalog)
            catalogField(catalog: $newdata.remotecatalog,
                         placeholder: "Destination folder (required)",
                         focus: .remotecatalogField,
                         selectedValue: newdata.selectedconfig?.offsiteCatalog,
                         showErrorBorder: !newdata.localcatalog.isEmpty && newdata.remotecatalog.isEmpty ||
                         newdata.localcatalog.isEmpty && !newdata.remotecatalog.isEmpty)
        }
    }

    var localandremotecatalogsyncremote: some View {
        Section("Folders") {
            catalogField(catalog: $newdata.remotecatalog,
                         placeholder: "Source Folder (required)",
                         focus: .remotecatalogField,
                         selectedValue: newdata.selectedconfig?.offsiteCatalog)
            catalogField(catalog: $newdata.localcatalog,
                         placeholder: "Remote Folder (required)",
                         focus: .localcatalogField,
                         selectedValue: newdata.selectedconfig?.localCatalog,
                         showErrorBorder: !newdata.localcatalog.isEmpty && newdata.remotecatalog.isEmpty ||
                         newdata.localcatalog.isEmpty && !newdata.remotecatalog.isEmpty)
        }
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
                placeholder: "Remote user",
                focus: .remoteuserField,
                selectedValue: newdata.selectedconfig?.offsiteUsername,
                showErrorBorder: newdata.remoteuser.isEmpty && !newdata.remoteserver.isEmpty
            )
            remoteField(
                value: $newdata.remoteserver,
                placeholder: "Remote server",
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
                    .border(showErrorBorder ? Color.red : Color.clear, width: 2)
            } else {
                TextField(placeholder, text: value)
                    .focused($focusField, equals: focus)
                    .textContentType(.none).submitLabel(submitLabel)
                    .onAppear { if let val = selectedValue { value.wrappedValue = val } }
                    .border(showErrorBorder ? Color.red : Color.clear, width: 2)
            }
        }
    }

    var trailingslash: some View {
        Picker("Trailing /", selection: $newdata.trailingslashoptions) {
            ForEach(TrailingSlash.allCases) { Text($0.description).tag($0) }
        }
        .pickerStyle(.menu)
        .onChange(of: newdata.trailingslashoptions) {
            UserDefaults.standard.set(newdata.trailingslashoptions.rawValue, forKey: "trailingslashoptions")
        }
        .onAppear { loadTrailingSlashPreference() }
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

    var catalogSectionView: some View {
        Group {
            if newdata.selectedrsynccommand == .syncremote {
                localandremotecatalogsyncremote
            } else {
                localandremotecatalog
                    .disabled(selectedconfig?.task == SharedReference.shared.snapshot)
            }
        }
    }

    var updateButton: some View {
        Button("Update", systemImage: "arrow.down") {
            onUpdate?()
        }
        .help("Update task")
    }

    var saveURLSection: some View {
        Group {
            Toggle("Show save URL", isOn: $newdata.showsaveurls).toggleStyle(.switch)
            if newdata.showsaveurls {
                ConditionalGlassButton(systemImage: "square.and.arrow.down",
                                       text: "URL Estimate",
                                       helpText: "URL Estimate & Synchronize") {
                    let data = WidgetURLstrings(urletimate: stringestimate)
                    Task { @MainActor in
                        await WriteWidgetsURLStringsJSON.write(data)
                    }
                }
            }
        }
    }

    var body: some View {

        switch mode {
        case .add:
            Form {
                pickerselecttypeoftask

                trailingslash
                synchronizeID
                catalogSectionView
                remoteuserandserver
            }
            .formStyle(.grouped)
        case .update:
            Form {
                trailingslash
                synchronizeID
                catalogSectionView
                remoteuserandserver

                if showSnapshot { snapshotnum }
                saveURLSection
                updateButton

            }
            .formStyle(.grouped)
        }
    }
}
