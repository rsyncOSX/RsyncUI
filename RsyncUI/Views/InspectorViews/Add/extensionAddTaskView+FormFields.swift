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
        Section(header: Text("Synchronize ID").modifier(FixedTag(200, .leading)).font(.title3).fontWeight(.bold)) {
            if newdata.selectedconfig == nil {
                EditValueScheme(400, "Add synchronize ID", $newdata.backupID)
                    .focused($focusField, equals: .synchronizeIDField)
                    .textContentType(.none).submitLabel(.continue)
            } else {
                EditValueScheme(400, nil, $newdata.backupID)
                    .focused($focusField, equals: .synchronizeIDField)
                    .textContentType(.none).submitLabel(.continue)
                    .onAppear { if let id = newdata.selectedconfig?.backupID { newdata.backupID = id } }
            }
        }
    }

    var snapshotnum: some View {
        Section(header: Text("Snapshotnumber").modifier(FixedTag(200, .leading))) {
            EditValueScheme(400, nil, $newdata.snapshotnum)
                .focused($focusField, equals: .snapshotnumField)
                .textContentType(.none).submitLabel(.return)
                .disabled(!changesnapshotnum)
            ToggleViewDefault(text: "Change snapshotnumber", binding: $changesnapshotnum)
        }
    }

    var localandremotecatalog: some View {
        Section(header: Text("Folder parameters").modifier(FixedTag(200, .leading)).font(.title3).fontWeight(.bold)) {
            catalogField(catalog: $newdata.localcatalog,
                         placeholder: "Add Source folder - required",
                         focus: .localcatalogField,
                         selectedValue: newdata.selectedconfig?.localCatalog)
            catalogField(catalog: $newdata.remotecatalog,
                         placeholder: "Add Destination folder - required",
                         focus: .remotecatalogField,
                         selectedValue: newdata.selectedconfig?.offsiteCatalog,
                         showErrorBorder: !newdata.localcatalog.isEmpty && newdata.remotecatalog.isEmpty ||
                             newdata.localcatalog.isEmpty && !newdata.remotecatalog.isEmpty)
        }
    }

    var localandremotecatalogsyncremote: some View {
        Section(header: Text("Folder parameters").modifier(FixedTag(200, .leading)).font(.title3).fontWeight(.bold)) {
            catalogField(catalog: $newdata.remotecatalog,
                         placeholder: "Add Source folder - required",
                         focus: .remotecatalogField,
                         selectedValue: newdata.selectedconfig?.offsiteCatalog)
            catalogField(catalog: $newdata.localcatalog,
                         placeholder: "Add Remote folder - required",
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
                EditValueScheme(400, placeholder, catalog)
                    .focused($focusField, equals: focus)
                    .textContentType(.none).submitLabel(.continue)
                    .border(showErrorBorder ? Color.red : Color.clear, width: 2)
            } else {
                EditValueScheme(400, nil, catalog)
                    .focused($focusField, equals: focus)
                    .textContentType(.none).submitLabel(.continue)
                    .onAppear { if let value = selectedValue { catalog.wrappedValue = value } }
                    .border(showErrorBorder ? Color.red : Color.clear, width: 2)
            }
            OpencatalogView(selecteditem: catalog, catalogs: true)
        }
    }

    var remoteuserandserver: some View {
        Section(header: Text("Remote parameters").modifier(FixedTag(200, .leading)).font(.title3).fontWeight(.bold)) {
            remoteField(
                value: $newdata.remoteuser,
                placeholder: "Add remote user",
                focus: .remoteuserField,
                selectedValue: newdata.selectedconfig?.offsiteUsername,
                showErrorBorder: newdata.remoteuser.isEmpty && !newdata.remoteserver.isEmpty
            )
            remoteField(
                value: $newdata.remoteserver,
                placeholder: "Add remote server",
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
                EditValueScheme(400, placeholder, value)
                    .focused($focusField, equals: focus)
                    .textContentType(.none).submitLabel(submitLabel)
                    .border(showErrorBorder ? Color.red : Color.clear, width: 2)
            } else {
                EditValueScheme(400, nil, value)
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
        .pickerStyle(DefaultPickerStyle()).frame(width: 180)
        .onChange(of: newdata.trailingslashoptions) {
            UserDefaults.standard.set(newdata.trailingslashoptions.rawValue, forKey: "trailingslashoptions")
        }
        .onAppear { loadTrailingSlashPreference() }
    }

    var pickerselecttypeoftask: some View {
        Picker("Action", selection: $newdata.selectedrsynccommand) {
            ForEach(TypeofTask.allCases) { Text($0.description).tag($0) }
        }
        .pickerStyle(DefaultPickerStyle()).frame(width: 180)
        .onChange(of: newdata.selectedrsynccommand) {
            UserDefaults.standard.set(newdata.selectedrsynccommand.rawValue, forKey: "selectedrsynccommand")
        }
        .onAppear { loadRsyncCommandPreference() }
    }
}
