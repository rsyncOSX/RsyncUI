//
//  AddTaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/12/2023.
//
// swiftlint:disable file_length type_body_length

import SwiftUI

enum AddTaskDestinationView: String, Identifiable {
    case profileview, shelltaskview, homecatalogs
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
    @Bindable var profilenames: Profilenames

    @State private var selectedconfig: SynchronizeConfiguration?
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    // Which view to show
    @State var path: [AddTasks] = []

    var choosecatalog = true

    enum AddConfigurationField: Hashable {
        case localcatalogField
        case remotecatalogField
        case remoteuserField
        case remoteserverField
        case backupIDField
    }

    @FocusState private var focusField: AddConfigurationField?
    // Reload and show table data
    @State private var confirmcopyandpaste: Bool = false

    var body: some View {
        NavigationStack(path: $path) {
            Form {
                ZStack {
                    HStack {
                        // For center
                        Spacer()

                        // Column 1
                        VStack(alignment: .leading) {
                            pickerselecttypeoftask

                            if newdata.selectedrsynccommand == .syncremote {
                                VStack(alignment: .leading) { localandremotecatalogsyncremote }

                            } else {
                                VStack(alignment: .leading) { localandremotecatalog }
                            }

                            VStack(alignment: .leading) {
                                ToggleViewDefault(NSLocalizedString("Don´t add /", comment: ""),
                                                  $newdata.donotaddtrailingslash)
                            }

                            VStack(alignment: .leading) { synchronizeid }

                            VStack(alignment: .leading) { remoteuserandserver }

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
                                    }
                                }
                        }
                    }
                }
            }
            .lineSpacing(2)
            .padding()
            .onSubmit {
                switch focusField {
                case .localcatalogField:
                    focusField = .remotecatalogField
                case .remotecatalogField:
                    focusField = .backupIDField
                case .remoteuserField:
                    focusField = .remoteserverField
                case .remoteserverField:
                    if newdata.selectedconfig == nil {
                        addconfig()
                    } else {
                        validateandupdate()
                    }
                    focusField = nil
                case .backupIDField:
                    if newdata.remotestorageislocal == true,
                       newdata.selectedconfig == nil
                    {
                        addconfig()
                    } else {
                        focusField = .remoteuserField
                    }
                default:
                    return
                }
            }
            .alert(isPresented: $newdata.alerterror,
                   content: { Alert(localizedError: newdata.error)
                   })

            .navigationDestination(for: AddTasks.self) { which in
                makeView(view: which.task)
            }
            .toolbar {
                if newdata.selectedconfig != nil {
                    ToolbarItem {
                        Button {
                            validateandupdate()
                        } label: {
                            Image(systemName: "square.and.arrow.down.fill")
                                .foregroundColor(Color(.blue))
                        }
                        .help("Update task")
                    }
                } else {
                    ToolbarItem {
                        Button {
                            addconfig()
                        } label: {
                            Image(systemName: "plus.app.fill")
                                .foregroundColor(Color(.blue))
                        }
                        .help("Add task")
                    }
                }

                ToolbarItem {
                    Button {
                        path.append(AddTasks(task: .homecatalogs))
                    } label: {
                        Image(systemName: "house.fill")
                    }
                    .help("Home catalogs")
                }

                ToolbarItem {
                    Button {
                        path.append(AddTasks(task: .profileview))
                    } label: {
                        Image(systemName: "arrow.triangle.branch")
                    }
                    .help("Profiles")
                }

                ToolbarItem {
                    Button {
                        path.append(AddTasks(task: .shelltaskview))
                    } label: {
                        Image(systemName: "fossil.shell.fill")
                    }
                    .help("Shell commands")
                }
            }
        }
    }

    @ViewBuilder
    func makeView(view: AddTaskDestinationView) -> some View {
        switch view {
        case .profileview:
            AddProfileView(rsyncUIdata: rsyncUIdata,
                           profilenames: profilenames,
                           selectedprofile: $selectedprofile)
        case .shelltaskview:
            AddPreandPostView(rsyncUIdata: rsyncUIdata,
                              profilenames: profilenames,
                              selectedprofile: $selectedprofile)
        case .homecatalogs:
            HomeCatalogsView(catalog: $newdata.assistlocalcatalog,
                             path: $path,
                             homecatalogs: {
                                 if let atpath = NamesandPaths(.configurations).userHomeDirectoryPath {
                                     var catalogs = [Catalognames]()
                                     do {
                                         for folders in try Folder(path: atpath).subfolders {
                                             catalogs.append(Catalognames(folders.name))
                                         }
                                         return catalogs
                                     } catch {
                                         return []
                                     }
                                 }
                                 return []
                             }())
                .onChange(of: newdata.assistlocalcatalog) {
                    newdata.assistfunclocalcatalog(newdata.assistlocalcatalog)
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
            .focused($focusField, equals: .backupIDField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var headerID: some View {
        Text("Synchronize ID")
            .modifier(FixedTag(200, .leading))
    }

    var synchronizeid: some View {
        Section(header: headerID) {
            // Synchronize ID
            if newdata.selectedconfig == nil { setID } else {
                EditValue(300, nil, $newdata.backupID)
                    .focused($focusField, equals: .backupIDField)
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
            return .synchronize
        case SharedReference.shared.syncremote:
            return .syncremote
        case SharedReference.shared.snapshot:
            return .snapshot
        default:
            return .synchronize
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
        var items = [CopyItem]()
        for i in 0 ..< (rsyncUIdata.configurations?.count ?? 0) {
            let item = CopyItem(id: rsyncUIdata.configurations?[i].id ?? UUID(),
                                hiddenID: rsyncUIdata.configurations?[i].hiddenID ?? -1,
                                task: rsyncUIdata.configurations?[i].task ?? "")
            items.append(item)
        }
        return items
    }
}

extension AddTaskView {
    func addconfig() {
        rsyncUIdata.configurations = newdata.addconfig(selectedprofile, rsyncUIdata.configurations)
    }

    func validateandupdate() {
        rsyncUIdata.configurations = newdata.validateandupdate(selectedprofile, rsyncUIdata.configurations)
    }
}

// swiftlint:enable file_length type_body_length
