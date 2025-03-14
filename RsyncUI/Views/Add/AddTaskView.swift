//
//  AddTaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/12/2023.
//
// swiftlint:disable file_length type_body_length line_length

import SwiftUI

enum AddTaskDestinationView: String, Identifiable {
    case homecatalogs, verify
    var id: String { rawValue }
}

struct AddTasks: Hashable, Identifiable {
    let id = UUID()
    var task: AddTaskDestinationView
}

enum AddConfigurationField: Hashable {
    case localcatalogField
    case remotecatalogField
    case remoteuserField
    case remoteserverField
    case synchronizeIDField
    case snapshotnumField
}

struct AddTaskView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedprofile: String?
    @Binding var addtasknavigation: [AddTasks]
    @Binding var useglobalchanges: Bool

    @State private var newdata = ObservableAddConfigurations()
    @State private var selectedconfig: SynchronizeConfiguration?
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    // Enable change snapshotnum
    @State private var changesnapshotnum: Bool = false

    @FocusState private var focusField: AddConfigurationField?
    // Reload and show table data
    @State private var confirmcopyandpaste: Bool = false

    // URL strings
    @State private var urlverify: URL?
    @State private var urlestimate: URL?
    @State private var stringverify: String = ""
    @State private var stringestimate: String = ""

    var body: some View {
        NavigationStack(path: $addtasknavigation) {
            HStack {
                // Column 1
                VStack(alignment: .leading) {
                    HStack {
                        pickerselecttypeoftask
                            .disabled(selectedconfig != nil)

                        VStack(alignment: .leading) {
                            ToggleViewDefault(text: NSLocalizedString("Don´t add /", comment: ""),
                                              binding: $newdata.donotaddtrailingslash)
                        }
                    }

                    if newdata.selectedrsynccommand == .syncremote {
                        VStack(alignment: .leading) { localandremotecatalogsyncremote }

                    } else {
                        VStack(alignment: .leading) { localandremotecatalog }
                            .disabled(selectedconfig?.task == SharedReference.shared.snapshot)
                    }

                    VStack(alignment: .leading) { synchronizeID }

                    VStack(alignment: .leading) { remoteuserandserver }
                        .disabled(selectedconfig?.task == SharedReference.shared.snapshot)

                    if selectedconfig?.task == SharedReference.shared.snapshot {
                        VStack(alignment: .leading) { snapshotnum }
                    }

                    Spacer()

                    if let selectedconfig,
                       selectedconfig.task == SharedReference.shared.synchronize {
                        VStack(alignment: .leading) {
                            Text("URL for Estimate & Synchronize")

                            HStack {
                                EditValueTwoLines(300, "Select a task to save an URL for Estimate & Synchronize", $stringestimate)

                                Button {
                                    let data = WidgetURLstrings(urletimate: stringestimate, urlverify: stringverify)
                                    WriteWidgetsURLStringsJSON(data, .estimate)
                                } label: {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(.blue))
                                }
                                .disabled(stringestimate.isEmpty)
                                .help(stringestimate)
                            }

                            if selectedconfig.offsiteServer.isEmpty == false {
                                
                                Text("URL for Verify")

                                HStack {
                                    EditValueTwoLines(300, "Select a task to save an URL for Verify", $stringverify)

                                    Button {
                                        let data = WidgetURLstrings(urletimate: stringestimate, urlverify: stringverify)
                                        WriteWidgetsURLStringsJSON(data, .verify)
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color(.blue))
                                    }
                                    .disabled(stringverify.isEmpty)
                                    .help(stringverify)
                                }
                            }
                            
                        }
                    }

                    Spacer()

                    ToggleViewDefault(text: NSLocalizedString("Toggle global changes", comment: ""),
                                      binding: $useglobalchanges)
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

                                    // URLs
                                    if selectedconfig?.task == SharedReference.shared.synchronize {
                                        let deeplinkurl = DeeplinkURL()
                                        
                                        if selectedconfig?.offsiteServer.isEmpty == false {
                                            // Create verifyremote URL
                                            urlverify = deeplinkurl.createURLloadandverify(valueprofile: rsyncUIdata.profile ?? "default", valueid: selectedconfig?.backupID ?? "Synchronize ID")
                                            stringverify = urlverify?.absoluteString ?? ""
                                        }
                                        // Create estimate and synchronize URL
                                        urlestimate = deeplinkurl.createURLestimateandsynchronize(valueprofile: rsyncUIdata.profile ?? "default")
                                        stringestimate = urlestimate?.absoluteString ?? ""

                                    } else {
                                        stringverify = ""
                                        stringestimate = ""
                                    }

                                } else {
                                    selectedconfig = nil
                                    newdata.updateview(nil)
                                    // URLs
                                    urlverify = nil
                                    urlestimate = nil
                                    stringverify = ""
                                    stringestimate = ""
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
                if newdata.verifyremotestorageislocal() == true,
                   newdata.selectedconfig == nil
                {
                    addconfig()
                } else {
                    focusField = .remoteuserField
                }
            case .snapshotnumField:
                validateandupdate()
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
            if newdata.selectedconfig != nil,
               newdata.selectedconfig?.task != SharedReference.shared.halted
            {
                ToolbarItem {
                    Button {
                        addtasknavigation.append(AddTasks(task: .verify))
                    } label: {
                        Image(systemName: "play.fill")
                            .foregroundColor(.blue)
                    }
                    .help("Verify task")
                }
            }

            if newdata.selectedconfig != nil {
                ToolbarItem {
                    Button {
                        validateandupdate()
                    } label: {
                        if notifydataisupdated {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(.red))
                        } else {
                            Image(systemName: "checkmark.circle")
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
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(.blue))
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
        .navigationTitle("Add and update tasks")
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
                OpencatalogView(selecteditem: $newdata.localcatalog, catalogs: true)
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
                OpencatalogView(selecteditem: $newdata.remotecatalog, catalogs: true)
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
                OpencatalogView(selecteditem: $newdata.localcatalog, catalogs: true)
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
                OpencatalogView(selecteditem: $newdata.remotecatalog, catalogs: true)
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
            let copy = configurations.map { record in
                CopyItem(id: record.id,
                         task: record.task)
            }
            return copy
        }
        return []
    }

    var notifydataisupdated: Bool {
        guard let selectedconfig else { return false }
        if newdata.localcatalog != selectedconfig.localCatalog ||
            newdata.remotecatalog != selectedconfig.offsiteCatalog ||
            newdata.backupID != selectedconfig.backupID ||
            newdata.remoteuser != selectedconfig.offsiteUsername ||
            newdata.remoteserver != selectedconfig.offsiteServer
        {
            return true
        }
        return false
    }
}

extension AddTaskView {
    func addconfig() {
        rsyncUIdata.configurations = newdata.addconfig(selectedprofile, rsyncUIdata.configurations)
        if SharedReference.shared.duplicatecheck {
            if let configurations = rsyncUIdata.configurations {
                VerifyDuplicates(configurations)
            }
        }
    }

    func validateandupdate() {
        rsyncUIdata.configurations = newdata.updateconfig(selectedprofile, rsyncUIdata.configurations)
        selecteduuids.removeAll()
    }
}

// swiftlint:enable file_length type_body_length line_length
