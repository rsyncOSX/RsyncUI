//
//  TaskDetailView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/12/2023.
//

import OSLog
import SwiftUI

enum TypeofTask: String, CaseIterable, Identifiable, CustomStringConvertible {
    case synchronize
    case snapshot
    case syncremote

    var id: String {
        rawValue
    }

    var description: String {
        rawValue.localizedLowercase
    }
}

extension TaskDetailView {

    var updateButton: some View {
        ConditionalGlassButton(systemImage: "arrow.down", text: "Update", helpText: "Update task") {
            let profile = rsyncUIdata.profile
            rsyncUIdata.configurations = newdata.updateConfig(profile, rsyncUIdata.configurations)
            onUpdateAction?()
        }
    }

    var saveURLSection: some View {
        Section(header: Text("Show save URL").font(.title3).fontWeight(.bold)) {
            HStack {
                Toggle("", isOn: $newdata.showsaveurls).toggleStyle(.switch)
                if newdata.showsaveurls {
                    ConditionalGlassButton(systemImage: "square.and.arrow.down",
                                           text: "URL Estimate",
                                           helpText: "URL Estimate & Synchronize") {
                        let data = WidgetURLstrings(urletimate: stringestimate)
                        WriteWidgetsURLStringsJSON(data)
                    }
                }
            }
        }
    }

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

    var synchronizeID: some View {
        Section(header: Text("Synchronize ID").modifier(FixedTag(200, .leading)).font(.title3).fontWeight(.bold)) {
            if newdata.selectedconfig == nil {
                EditValueScheme(400, "Add synchronize ID", $newdata.backupID)
                    .textContentType(.none).submitLabel(.continue)
            } else {
                EditValueScheme(400, nil, $newdata.backupID)
                    .textContentType(.none).submitLabel(.continue)
                    .onAppear { if let id = newdata.selectedconfig?.backupID { newdata.backupID = id } }
            }
        }
    }

    var snapshotnum: some View {
        Section(header: Text("Snapshotnumber").modifier(FixedTag(200, .leading))) {
            EditValueScheme(400, nil, $newdata.snapshotnum)
                .textContentType(.none).submitLabel(.return)
                .disabled(!changesnapshotnum)
            ToggleViewDefault(text: "Change snapshotnumber", binding: $changesnapshotnum)
        }
    }

    var localandremotecatalog: some View {
        Section(header: Text("Folder parameters").modifier(FixedTag(200, .leading)).font(.title3).fontWeight(.bold)) {
            catalogField(catalog: $newdata.localcatalog,
                         placeholder: "Add Source folder - required",
                         selectedValue: newdata.selectedconfig?.localCatalog)
            catalogField(catalog: $newdata.remotecatalog,
                         placeholder: "Add Destination folder - required",
                         selectedValue: newdata.selectedconfig?.offsiteCatalog,
                         showErrorBorder: !newdata.localcatalog.isEmpty && newdata.remotecatalog.isEmpty ||
                             newdata.localcatalog.isEmpty && !newdata.remotecatalog.isEmpty)
        }
    }

    var localandremotecatalogsyncremote: some View {
        Section(header: Text("Folder parameters").modifier(FixedTag(200, .leading)).font(.title3).fontWeight(.bold)) {
            catalogField(catalog: $newdata.remotecatalog,
                         placeholder: "Add Source folder - required",
                         selectedValue: newdata.selectedconfig?.offsiteCatalog)
            catalogField(catalog: $newdata.localcatalog,
                         placeholder: "Add Remote folder - required",
                         selectedValue: newdata.selectedconfig?.localCatalog,
                         showErrorBorder: !newdata.localcatalog.isEmpty && newdata.remotecatalog.isEmpty ||
                             newdata.localcatalog.isEmpty && !newdata.remotecatalog.isEmpty)
        }
    }

    func catalogField(catalog: Binding<String>, placeholder: String,
                      selectedValue: String?,
                      showErrorBorder: Bool = false) -> some View {
        HStack {
            if newdata.selectedconfig == nil {
                EditValueScheme(400, placeholder, catalog)
                    .textContentType(.none).submitLabel(.continue)
                    .border(showErrorBorder ? Color.red : Color.clear, width: 2)
            } else {
                EditValueScheme(400, nil, catalog)

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
    
    var catalogSectionView: some View {
        Group {
            if newdata.selectedrsynccommand == .syncremote {
                VStack(alignment: .leading) { localandremotecatalogsyncremote }
            } else {
                VStack(alignment: .leading) { localandremotecatalog }
                    .disabled(selectedconfig?.task == SharedReference.shared.snapshot)
            }
        }
    }
}

struct TaskDetailView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var newdata: ObservableAddConfigurations

    @Binding var selectedconfig: SynchronizeConfiguration?
    @Binding var changesnapshotnum: Bool
    @Binding var stringestimate: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                updateButton
                trailingslash
            }

            synchronizeID
            catalogSectionView

            VStack(alignment: .leading) { remoteuserandserver }

            if selectedconfig?.task == SharedReference.shared.snapshot {
                VStack(alignment: .leading) { snapshotnum }
            }

            saveURLSection
        }
        
    }
    
    var onUpdateAction: (() -> Void)? = nil
    func onUpdate(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onUpdateAction = action
        return copy
    }

}
