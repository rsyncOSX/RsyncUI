//
//  AddTaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/12/2023.
//
// swiftlint:disable file_length type_body_length line_length

import SwiftUI

enum AddTaskDestinationView: String, Identifiable {
    case homecatalogs, verify, global
    var id: String { rawValue }
}

struct AddTasks: Hashable, Identifiable {
    let id = UUID()
    var task: AddTaskDestinationView
}

struct AddTaskView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @State private var newdata = ObservableAddConfigurations()
    @Binding var selectedprofile: String?
    @Binding var addtasknavigation: [AddTasks]

    @State private var selectedconfig: SynchronizeConfiguration?
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()

    // Update pressed
    @State private var updated: Bool = false
    // Enable change snapshotnum
    @State private var changesnapshotnum: Bool = false

    var choosecatalog = true

    enum AddConfigurationField: Hashable {
        case localcatalogField
        case remotecatalogField
        case remoteuserField
        case remoteserverField
        case synchronizeIDField
        case snapshotnumField
    }

    @FocusState private var focusField: AddConfigurationField?
    // Reload and show table data
    @State private var confirmcopyandpaste: Bool = false

    var body: some View {
        NavigationStack(path: $addtasknavigation) {
            HStack {
                // Column 1
                VStack(alignment: .leading) {
                    pickerselecttypeoftask
                        .disabled(selectedconfig != nil)

                    if newdata.selectedrsynccommand == .syncremote {
                        VStack(alignment: .leading) { localandremotecatalogsyncremote }

                    } else {
                        VStack(alignment: .leading) { localandremotecatalog }
                            .disabled(selectedconfig?.task == SharedReference.shared.snapshot)
                    }

                    VStack(alignment: .leading) {
                        ToggleViewDefault(text: NSLocalizedString("Don´t add /", comment: ""),
                                          binding: $newdata.donotaddtrailingslash)
                    }

                    VStack(alignment: .leading) { synchronizeID }

                    VStack(alignment: .leading) { remoteuserandserver }
                        .disabled(selectedconfig?.task == SharedReference.shared.snapshot)

                    if selectedconfig?.task == SharedReference.shared.snapshot {
                        VStack(alignment: .leading) { snapshotnum }
                    }

                    Spacer()
                }
                // Column 2
                VStack(alignment: .leading) {
                    ListofTasksAddView(rsyncUIdata: rsyncUIdata,
                                       selecteduuids: $selecteduuids)
                        .onChange(of: selecteduuids) {
                            if let configurations = rsyncUIdata.configurations {
                                if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                                    selectedconfig = configurations[index]
                                    newdata.updateview(configurations[index])
                                } else {
                                    selectedconfig = nil
                                    newdata.updateview(nil)
                                    updated = false
                                }
                            }
                        }
                        .copyable(copyitems.filter { selecteduuids.contains($0.id) })
                        .pasteDestination(for: CopyItem.self) { items in
                            newdata.preparecopyandpastetasks(items,
                                                             rsyncUIdata.configurations ?? [])
                            guard items.count > 0 else { return }
                            confirmcopyandpaste = true
                        } validator: { items in
                            items.filter { $0.task != SharedReference.shared.snapshot }
                        }
                        .confirmationDialog(
                            Text("Copy ^[\(newdata.copyandpasteconfigurations?.count ?? 0) configuration](inflect: true)"),
                            isPresented: $confirmcopyandpaste
                        ) {
                            Button("Copy") {
                                confirmcopyandpaste = false
                                rsyncUIdata.configurations =
                                    newdata.writecopyandpastetasks(rsyncUIdata.profile,
                                                                   rsyncUIdata.configurations ?? [])
                                if SharedReference.shared.duplicatecheck {
                                    if let configurations = rsyncUIdata.configurations {
                                        VerifyDuplicates(configurations)
                                    }
                                }
                            }
                        }
                }
            }
        }
        .onSubmit {
            switch focusField {
            case .localcatalogField:
                focusField = .remotecatalogField
            case .remotecatalogField:
                focusField = .synchronizeIDField
            case .remoteuserField:
                focusField = .remoteserverField
            case .remoteserverField:
                if newdata.selectedconfig == nil {
                    addconfig()
                } else {
                    validateandupdate()
                }
                focusField = nil
            case .synchronizeIDField:
                if newdata.remotestorageislocal == true,
                   newdata.selectedconfig == nil
                {
                    addconfig()
                } else {
                    focusField = .remoteuserField
                }
            case .snapshotnumField:
                validateandupdate()
                focusField = nil
            default:
                return
            }
        }
        .onChange(of: rsyncUIdata.profile) {
            newdata.resetform()
            selecteduuids.removeAll()
            selectedconfig = nil
        }
        .toolbar {
            ToolbarItem {
                Button {
                    addtasknavigation.append(AddTasks(task: .global))
                } label: {
                    Image(systemName: "globe")
                }
                .help("Global change")
            }

            if newdata.selectedconfig != nil {
                ToolbarItem {
                    Button {
                        addtasknavigation.append(AddTasks(task: .verify))
                    } label: {
                        Image(systemName: "flag.checkered")
                    }
                    .help("Verify task")
                }
            }

            if newdata.selectedconfig != nil {
                ToolbarItem {
                    Button {
                        validateandupdate()
                    } label: {
                        if updated == false {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(Color(.blue))
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(.blue))
                        }
                    }
                    .help("Update task")
                }
            } else {
                ToolbarItem {
                    Button {
                        addconfig()
                    } label: {
                        if updated == false {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(Color(.blue))
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(.blue))
                        }
                    }
                    .help("Add task")
                }
            }

            ToolbarItem {
                Button {
                    addtasknavigation.append(AddTasks(task: .homecatalogs))
                } label: {
                    Image(systemName: "house.fill")
                }
                .help("Home catalogs")
            }
        }
        .navigationDestination(for: AddTasks.self) { which in
            makeView(view: which.task)
        }
        .padding()
    }

    @MainActor @ViewBuilder
    func makeView(view: AddTaskDestinationView) -> some View {
        switch view {
        case .homecatalogs:
            HomeCatalogsView(newdata: newdata,
                             path: $addtasknavigation,
                             homecatalogs: {
                                 let fm = FileManager.default
                                 if let atpathURL = Homepath().userHomeDirectoryURLPath {
                                     var catalogs = [Catalognames]()
                                     do {
                                         for filesandfolders in try
                                             fm.contentsOfDirectory(at: atpathURL, includingPropertiesForKeys: nil)
                                             where filesandfolders.hasDirectoryPath
                                         {
                                             catalogs.append(Catalognames(filesandfolders.lastPathComponent))
                                         }
                                         return catalogs
                                     } catch {
                                         return []
                                     }
                                 }
                                 return []
                             }(),

                             attachedVolumes: {
                                 let keys: [URLResourceKey] = [.volumeNameKey,
                                                               .volumeIsRemovableKey,
                                                               .volumeIsEjectableKey]
                                 let paths = FileManager()
                                     .mountedVolumeURLs(includingResourceValuesForKeys: keys,
                                                        options: [])
                                 var volumesarray = [AttachedVolumes]()
                                 if let urls = paths {
                                     for url in urls {
                                         let components = url.pathComponents
                                         if components.count > 1, components[1] == "Volumes" {
                                             volumesarray.append(AttachedVolumes(url))
                                         }
                                     }
                                 }
                                 if volumesarray.count > 0 {
                                     return volumesarray
                                 } else {
                                     return []
                                 }
                             }())
        case .verify:
            if let config = selectedconfig {
                OutputRsyncVerifyView(config: config)
            }
        case .global:
            GlobalChangeTaskView(rsyncUIdata: rsyncUIdata)
        }
    }

    // Add and edit text values
    var setlocalcatalogsyncremote: some View {
        EditValue(300, NSLocalizedString("Add remote as local catalog - required", comment: ""),
                  $newdata.localcatalog)
    }

    var setremotecatalogsyncremote: some View {
        EditValue(300, NSLocalizedString("Add local as remote catalog - required", comment: ""),
                  $newdata.remotecatalog)
            .onChange(of: newdata.remotecatalog) {
                newdata.remotestorageislocal = newdata.verifyremotestorageislocal()
            }
    }

    var setlocalcatalog: some View {
        EditValue(300, NSLocalizedString("Add local catalog - required", comment: ""),
                  $newdata.localcatalog)
            .focused($focusField, equals: .localcatalogField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var setremotecatalog: some View {
        EditValue(300, NSLocalizedString("Add remote catalog - required", comment: ""),
                  $newdata.remotecatalog)
            .focused($focusField, equals: .remotecatalogField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    // Headers (in sections)
    var headerlocalremote: some View {
        Text("Catalog parameters")
            .modifier(FixedTag(200, .leading))
    }

    var localandremotecatalog: some View {
        Section(header: headerlocalremote) {
            HStack {
                // localcatalog
                if newdata.selectedconfig == nil { setlocalcatalog } else {
                    EditValue(300, nil, $newdata.localcatalog)
                        .focused($focusField, equals: .localcatalogField)
                        .textContentType(.none)
                        .submitLabel(.continue)
                        .onAppear(perform: {
                            if let catalog = newdata.selectedconfig?.localCatalog {
                                newdata.localcatalog = catalog
                            }
                        })
                }
                OpencatalogView(catalog: $newdata.localcatalog, choosecatalog: choosecatalog)
            }
            HStack {
                // remotecatalog
                if newdata.selectedconfig == nil { setremotecatalog } else {
                    EditValue(300, nil, $newdata.remotecatalog)
                        .focused($focusField, equals: .remotecatalogField)
                        .textContentType(.none)
                        .submitLabel(.continue)
                        .onAppear(perform: {
                            if let catalog = newdata.selectedconfig?.offsiteCatalog {
                                newdata.remotecatalog = catalog
                            }
                        })
                }
                OpencatalogView(catalog: $newdata.remotecatalog, choosecatalog: choosecatalog)
            }
        }
    }

    var localandremotecatalogsyncremote: some View {
        Section(header: headerlocalremote) {
            HStack {
                // localcatalog
                if newdata.selectedconfig == nil { setlocalcatalogsyncremote } else {
                    EditValue(300, nil, $newdata.localcatalog)
                        .onAppear(perform: {
                            if let catalog = newdata.selectedconfig?.localCatalog {
                                newdata.localcatalog = catalog
                            }
                        })
                }
                OpencatalogView(catalog: $newdata.localcatalog, choosecatalog: choosecatalog)
            }
            HStack {
                // remotecatalog
                if newdata.selectedconfig == nil { setremotecatalogsyncremote } else {
                    EditValue(300, nil, $newdata.remotecatalog)
                        .onAppear(perform: {
                            if let catalog = newdata.selectedconfig?.offsiteCatalog {
                                newdata.remotecatalog = catalog
                            }
                        })
                }
                OpencatalogView(catalog: $newdata.remotecatalog, choosecatalog: choosecatalog)
            }
        }
    }

    var setID: some View {
        EditValue(300, NSLocalizedString("Add synchronize ID", comment: ""),
                  $newdata.backupID)
            .focused($focusField, equals: .synchronizeIDField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var headerID: some View {
        Text("Synchronize ID")
            .modifier(FixedTag(200, .leading))
    }

    var synchronizeID: some View {
        Section(header: headerID) {
            // Synchronize ID
            if newdata.selectedconfig == nil { setID } else {
                EditValue(300, nil, $newdata.backupID)
                    .focused($focusField, equals: .synchronizeIDField)
                    .textContentType(.none)
                    .submitLabel(.continue)
                    .onAppear(perform: {
                        if let id = newdata.selectedconfig?.backupID {
                            newdata.backupID = id
                        }
                    })
            }
        }
    }

    var snapshotnumheader: some View {
        Text("Snapshotnumber")
            .modifier(FixedTag(200, .leading))
    }

    var snapshotnum: some View {
        Section(header: snapshotnumheader) {
            // Reset snapshotnum
            EditValue(300, nil, $newdata.snapshotnum)
                .focused($focusField, equals: .snapshotnumField)
                .textContentType(.none)
                .submitLabel(.return)
                .disabled(!changesnapshotnum)

            ToggleViewDefault(text: NSLocalizedString("Change snapshotnumber", comment: ""),
                              binding: $changesnapshotnum)
        }
    }

    var setremoteuser: some View {
        EditValue(300, NSLocalizedString("Add remote user", comment: ""),
                  $newdata.remoteuser)
            .focused($focusField, equals: .remoteuserField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var setremoteserver: some View {
        EditValue(300, NSLocalizedString("Add remote server", comment: ""),
                  $newdata.remoteserver)
            .focused($focusField, equals: .remoteserverField)
            .textContentType(.none)
            .submitLabel(.return)
    }

    var headerremote: some View {
        Text("Remote parameters")
            .modifier(FixedTag(200, .leading))
    }

    var remoteuserandserver: some View {
        Section(header: headerremote) {
            // Remote user
            if newdata.selectedconfig == nil { setremoteuser } else {
                EditValue(300, nil, $newdata.remoteuser)
                    .focused($focusField, equals: .remoteuserField)
                    .textContentType(.none)
                    .submitLabel(.continue)
                    .onAppear(perform: {
                        if let user = newdata.selectedconfig?.offsiteUsername {
                            newdata.remoteuser = user
                        }
                    })
            }
            // Remote server
            if newdata.selectedconfig == nil { setremoteserver } else {
                EditValue(300, nil, $newdata.remoteserver)
                    .focused($focusField, equals: .remoteserverField)
                    .textContentType(.none)
                    .submitLabel(.return)
                    .onAppear(perform: {
                        if let server = newdata.selectedconfig?.offsiteServer {
                            newdata.remoteserver = server
                        }
                    })
            }
        }
    }

    var selectpickervalue: TypeofTask {
        switch newdata.selectedconfig?.task {
        case SharedReference.shared.synchronize:
            .synchronize
        case SharedReference.shared.syncremote:
            .syncremote
        case SharedReference.shared.snapshot:
            .snapshot
        default:
            .synchronize
        }
    }

    var pickerselecttypeoftask: some View {
        Picker(NSLocalizedString("Task", comment: "") + ":",
               selection: $newdata.selectedrsynccommand)
        {
            ForEach(TypeofTask.allCases) { Text($0.description)
                .tag($0)
            }
            .onChange(of: newdata.selectedconfig) {
                newdata.selectedrsynccommand = selectpickervalue
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 140)
    }

    var copyitems: [CopyItem] {
        if let configurations = rsyncUIdata.configurations {
            let copyitems = configurations.map { record in
                CopyItem(id: record.id,
                         task: record.task)
            }
            return copyitems
        }
        return []
    }
}

extension AddTaskView {
    func addconfig() {
        rsyncUIdata.configurations = newdata.addconfig(selectedprofile, rsyncUIdata.configurations)
        updated = true
        Task {
            try await Task.sleep(seconds: 2)
            updated = false
        }
        if SharedReference.shared.duplicatecheck {
            if let configurations = rsyncUIdata.configurations {
                VerifyDuplicates(configurations)
            }
        }
    }

    func validateandupdate() {
        rsyncUIdata.configurations = newdata.updateconfig(selectedprofile, rsyncUIdata.configurations)
        updated = true
        selecteduuids.removeAll()
        Task {
            try await Task.sleep(seconds: 2)
            updated = false
        }
    }
}

// swiftlint:enable file_length type_body_length line_length
