//
//  TaskForm.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 13/12/2025.
//
import OSLog
import SwiftUI

private enum TaskFormMode {
    case add
    case update
}

struct TaskForm: View {
    private let mode: TaskFormMode

    @FocusState.Binding var focusField: AddConfigurationField?

    @Binding var newdata: ObservableAddConfigurations
    @State var changesnapshotnum: Bool = false
    @Binding var stringestimate: String

    var onUpdate: (() -> Void)?

    init(focusField: FocusState<AddConfigurationField?>.Binding, newdata: Binding<ObservableAddConfigurations>) {
        self.mode = .add
        _focusField = focusField
        _newdata = newdata
        _stringestimate = .constant("")
    }

    init(
        focusField: FocusState<AddConfigurationField?>.Binding,
        newdata: Binding<ObservableAddConfigurations>,
        stringestimate: Binding<String>,
        onUpdate: (() -> Void)?
    ) {
        self.mode = .update
        _focusField = focusField
        _newdata = newdata
        _stringestimate = stringestimate
        self.onUpdate = onUpdate
    }

    var showSnapshot: Bool {
        newdata.selectedconfig?.task == SharedReference.shared.snapshot
    }

    var synchronizeID: some View {
        Section("Synchronize ID") {
            TextField("Synchronize ID", text: $newdata.backupID)
                .focused($focusField, equals: .synchronizeIDField)
                .textContentType(.none)
                .submitLabel(.continue)
                .onAppear {
                    if let id = newdata.selectedconfig?.backupID {
                        newdata.backupID = id
                    }
                }
        }
    }

    var snapshotSection: some View {
        Section("Snapshot") {
            HStack {
                TextField("Snapshot Number", text: $newdata.snapshotnum)
                    .focused($focusField, equals: .snapshotnumField)
                    .textContentType(.none).submitLabel(.return)
                    .disabled(!changesnapshotnum)
                Toggle("Change Snapshot Number", isOn: $changesnapshotnum)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
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
                         showErrorBorder: newdata.localcatalog.isEmpty != newdata.remotecatalog.isEmpty)
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
                         showErrorBorder: newdata.localcatalog.isEmpty != newdata.remotecatalog.isEmpty)
        }
    }

    func catalogField(catalog: Binding<String>, placeholder: String,
                      focus: AddConfigurationField, selectedValue: String?,
                      showErrorBorder: Bool = false) -> some View
    {
        HStack {
            TextField(placeholder, text: catalog)
                .focused($focusField, equals: focus)
                .textContentType(.none).submitLabel(.continue)
                .onAppear {
                    if let value = selectedValue {
                        catalog.wrappedValue = value
                    }
                }
                .border(showErrorBorder ? Color.red : Color.clear, width: 2)
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
                     showErrorBorder: Bool = false) -> some View
    {
        TextField(placeholder, text: value)
            .focused($focusField, equals: focus)
            .textContentType(.none).submitLabel(submitLabel)
            .onAppear {
                if let val = selectedValue {
                    value.wrappedValue = val
                }
            }
            .border(showErrorBorder ? Color.red : Color.clear, width: 2)
    }

    var trailingslash: some View {
        Toggle("Trailing / (slash) on source folder", isOn: $newdata.trailingslash)
            .onChange(of: newdata.trailingslash) {
                UserDefaults.standard.set(newdata.trailingslash, forKey: "trailingslashoptions")
                
                if newdata.trailingslash {
                    if newdata.localcatalog.hasSuffix("/") == false {
                        newdata.localcatalog.append("/")
                    }
                } else {
                    if newdata.localcatalog.hasSuffix("/") {
                        newdata.localcatalog.removeLast()
                    }
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
    }

    @ViewBuilder
    var catalogSectionView: some View {
        if newdata.selectedrsynccommand == .syncremote {
            localandremotecatalogsyncremote
        } else {
            localandremotecatalog
                .disabled(newdata.selectedconfig?.task == SharedReference.shared.snapshot)
        }
    }

    var updateButton: some View {
        Button("Update", systemImage: "arrow.down") {
            onUpdate?()
        }
        .help("Update task")
    }

    @ViewBuilder
    var saveURLSection: some View {
        Toggle("Show save URL", isOn: $newdata.showsaveurls).toggleStyle(.switch)
        if newdata.showsaveurls {
            Button("URL Estimate", systemImage: "square.and.arrow.down") {
                let data = WidgetURLstrings(urletimate: stringestimate)
                Task { @MainActor in
                    await WriteWidgetsURLStringsJSON.write(data)
                }
            }
            .help("URL Estimate & Synchronize")
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

                if showSnapshot {
                    snapshotSection
                }
                saveURLSection
                updateButton
            }
            .formStyle(.grouped)
        }
    }
}
