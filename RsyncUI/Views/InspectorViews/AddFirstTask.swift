//
//  AddFirstTask.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/03/2026.
//

import SwiftUI

struct AddFirstTask: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @State var newdata = ObservableAddConfigurations()

    var body: some View {
        addTaskSheetView
    }

    var addTaskSheetView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Task").font(.headline)

            HStack {
                pickerselecttypeoftask
                trailingslash
            }

            synchronizeID
            catalogSectionView
            remoteuserandserver

            HStack {
                ConditionalGlassButton(systemImage: "plus",
                                       text: "Add",
                                       helpText: "Add task") {
                    addConfig()
                }
            }
        }
        .padding()
        .frame(minWidth: 600)
    }

    var pickerselecttypeoftask: some View {
        Picker("Action", selection: $newdata.selectedrsynccommand) {
            ForEach(TypeofTask.allCases) { Text($0.description).tag($0) }
        }
        .pickerStyle(DefaultPickerStyle()).frame(width: 180)
        .onChange(of: newdata.selectedrsynccommand) {
            UserDefaults.standard.set(newdata.selectedrsynccommand.rawValue, forKey: "selectedrsynccommand")
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
    }

    var synchronizeID: some View {
        Section(header: Text("Synchronize ID").modifier(FixedTag(200, .leading)).font(.title3).fontWeight(.bold)) {
            EditValueScheme(400, "Add synchronize ID", $newdata.backupID)
                .textContentType(.none).submitLabel(.continue)
        }
    }

    var catalogSectionView: some View {
        Group {
            if newdata.selectedrsynccommand == .syncremote {
                VStack(alignment: .leading) { localandremotecatalogsyncremote }
            } else {
                VStack(alignment: .leading) { localandremotecatalog }
            }
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
                      focus _: AddConfigurationField, selectedValue _: String?,
                      showErrorBorder: Bool = false) -> some View {
        HStack {
            EditValueScheme(400, placeholder, catalog)
                .textContentType(.none).submitLabel(.continue)
                .border(showErrorBorder ? Color.red : Color.clear, width: 2)
            OpencatalogView(selecteditem: catalog, catalogs: true)
        }
    }

    var remoteuserandserver: some View {
        Section(header: Text("Remote parameters").modifier(FixedTag(200, .leading)).font(.title3).fontWeight(.bold)) {
            remoteField(
                value: $newdata.remoteuser,
                placeholder: "Add remote user",
                selectedValue: newdata.selectedconfig?.offsiteUsername,
                showErrorBorder: newdata.remoteuser.isEmpty && !newdata.remoteserver.isEmpty
            )
            remoteField(
                value: $newdata.remoteserver,
                placeholder: "Add remote server",
                selectedValue: newdata.selectedconfig?.offsiteServer,
                submitLabel: .return,
                showErrorBorder: !newdata.remoteuser.isEmpty && newdata.remoteserver.isEmpty
            )
        }
    }

    func remoteField(value: Binding<String>, placeholder: String,
                     selectedValue: String?, submitLabel: SubmitLabel = .continue,
                     showErrorBorder: Bool = false) -> some View {
        Group {
            if newdata.selectedconfig == nil {
                EditValueScheme(400, placeholder, value)
                    .textContentType(.none).submitLabel(submitLabel)
                    .border(showErrorBorder ? Color.red : Color.clear, width: 2)
            } else {
                EditValueScheme(400, nil, value)
                    .textContentType(.none).submitLabel(submitLabel)
                    .onAppear { if let val = selectedValue { value.wrappedValue = val } }
                    .border(showErrorBorder ? Color.red : Color.clear, width: 2)
            }
        }
    }

    func addConfig() {
        let profile = rsyncUIdata.profile
        Task { @MainActor in
            rsyncUIdata.configurations = await newdata.addConfig(profile, rsyncUIdata.configurations)
            if SharedReference.shared.duplicatecheck {
                if let configurations = rsyncUIdata.configurations {
                    VerifyDuplicates(configurations)
                }
            }
        }
    }
}
