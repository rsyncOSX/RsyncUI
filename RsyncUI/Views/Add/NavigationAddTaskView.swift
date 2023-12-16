//
//  NavigationAddTaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/12/2023.
//
// swiftlint:disable file_length type_body_length

import SwiftUI

enum AddTaskDestinationView: String, Identifiable {
    case profileview, shelltaskview
    var id: String { rawValue }
}

struct AddTasks: Hashable, Identifiable {
    let id = UUID()
    var task: AddTaskDestinationView
}

struct NavigationAddTaskView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata

    @State private var newdata = ObservableAddConfigurations()
    @Binding var selectedprofile: String?
    @Binding var reload: Bool
    @Bindable var profilenames: Profilenames

    @State private var selectedconfig: Configuration?
    @State private var selecteduuids = Set<Configuration.ID>()
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
    // Modale view
    @State private var showprofileview = false
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

                            HStack {
                                localcatalogspicker

                                remoteuserpicker

                                remoteserverpicker
                            }

                            Spacer()
                        }

                        // Column 2

                        VStack(alignment: .leading) {
                            ListofTasksAddView(selecteduuids: $selecteduuids,
                                               reload: $reload)
                                .onChange(of: selecteduuids) {
                                    let selected = rsyncUIdata.configurations?.filter { config in
                                        selecteduuids.contains(config.id)
                                    }
                                    if (selected?.count ?? 0) == 1 {
                                        if let config = selected {
                                            selectedconfig = config[0]
                                            newdata.updateview(selectedconfig)
                                        }
                                    } else {
                                        selectedconfig = nil
                                        newdata.updateview(selectedconfig)
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
                                    NSLocalizedString("Copy configuration(s)", comment: "")
                                        + "?",
                                    isPresented: $confirmcopyandpaste
                                ) {
                                    Button("Copy") {
                                        confirmcopyandpaste = false
                                        newdata.writecopyandpastetasks(rsyncUIdata.profile,
                                                                       rsyncUIdata.configurations ?? [])
                                        reload = true
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
                            Image(systemName: "square.and.pencil")
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
            NavigationAddProfileView(profilenames: profilenames,
                                     selectedprofile: $selectedprofile,
                                     reload: $reload)
        case .shelltaskview:
            AddPreandPostView(profilenames: profilenames, selectedprofile: $selectedprofile, reload: $reload)
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

    var configurations: [Configuration]? {
        return rsyncUIdata.getallconfigurations()
    }

    var localcatalogspicker: some View {
        VStack(alignment: .trailing) {
            Text("Local catalogs")
                .font(Font.footnote)
            Picker("", selection: $newdata.assistlocalcatalog) {
                Text("").tag("")
                ForEach(assist.catalogs.sorted(by: <), id: \.self) { catalog in
                    Text(catalog)
                        .tag(catalog)
                }
            }
            .frame(width: 93)
            .accentColor(.blue)
            .onChange(of: newdata.assistlocalcatalog) {
                newdata.assistfunclocalcatalog(newdata.assistlocalcatalog)
            }
        }
    }

    var remoteuserpicker: some View {
        VStack(alignment: .trailing) {
            Text("Remote user")
                .font(Font.footnote)
            Picker("", selection: $newdata.assistremoteuser) {
                Text("").tag("")
                ForEach(assist.remoteusers.sorted(by: <), id: \.self) { remoteuser in
                    Text(remoteuser)
                        .tag(remoteuser)
                }
            }
            .frame(width: 93)
            .accentColor(.blue)
            .onChange(of: newdata.assistremoteuser) {
                newdata.assistfuncremoteuser(newdata.assistremoteuser)
            }
        }
    }

    var remoteserverpicker: some View {
        VStack(alignment: .trailing) {
            Text("Remote server")
                .font(Font.footnote)
            Picker("", selection: $newdata.assistremoteserver) {
                Text("").tag("")
                ForEach(assist.remoteservers.sorted(by: <), id: \.self) { remoteserver in
                    Text(remoteserver)
                        .tag(remoteserver)
                }
            }
            .frame(width: 93)
            .accentColor(.blue)
            .onChange(of: newdata.assistremoteserver) {
                newdata.assistfuncremoteserver(newdata.assistremoteserver)
            }
        }
    }

    var labelprofiletask: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                showprofileview = true
            })
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

    var assist: Assist {
        return Assist(configurations: rsyncUIdata.getallconfigurations())
    }
}

extension NavigationAddTaskView {
    func addconfig() {
        newdata.addconfig(selectedprofile, configurations)
        reload = newdata.reload
    }

    func validateandupdate() {
        newdata.validateandupdate(selectedprofile, configurations)
        reload = newdata.reload
    }
}

// swiftlint:enable file_length type_body_length
