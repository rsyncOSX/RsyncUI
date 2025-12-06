//
//  AddTaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/12/2023.
//

import OSLog
import SwiftUI

enum AddTaskDestinationView: String, Identifiable {
    case homecatalogs, globalchanges
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

enum TypeofTask: String, CaseIterable, Identifiable, CustomStringConvertible {
    case synchronize
    case snapshot
    case syncremote

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

struct AddTaskView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations

    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var addtaskpath: [AddTasks]

    @State private var newdata = ObservableAddConfigurations()
    @State private var selectedconfig: SynchronizeConfiguration?
    // Enable change snapshotnum
    @State private var changesnapshotnum: Bool = false

    @FocusState private var focusField: AddConfigurationField?
    // Reload and show table data
    @State private var confirmcopyandpaste: Bool = false
    // URL string
    @State private var stringestimate: String = ""

    // Present a help sheet
    @State private var showhelp: Bool = false

    var body: some View {
        NavigationStack(path: $addtaskpath) {
            HStack {
                // Column 1

                VStack(alignment: .leading) {
                    if newdata.selectedconfig != nil {
                        ConditionalGlassButton(
                            systemImage: "arrow.down",
                            text: "Update",
                            helpText: "Update task"
                        ) {
                            validateAndUpdate()
                        }
                    } else {
                        ConditionalGlassButton(
                            systemImage: "plus",
                            text: "Add",
                            helpText: "Add task"
                        ) {
                            addConfig()
                        }
                    }

                    VStack(alignment: .trailing) {
                        pickerselecttypeoftask
                            .disabled(selectedconfig != nil)

                        trailingslash
                    }
                    .padding(.bottom, 10)

                    VStack(alignment: .leading) { synchronizeID }

                    if newdata.selectedrsynccommand == .syncremote {
                        VStack(alignment: .leading) { localandremotecatalogsyncremote }

                    } else {
                        VStack(alignment: .leading) { localandremotecatalog }
                            .disabled(selectedconfig?.task == SharedReference.shared.snapshot)
                    }

                    VStack(alignment: .leading) { remoteuserandserver }
                        .disabled(selectedconfig?.task == SharedReference.shared.snapshot)

                    if selectedconfig?.task == SharedReference.shared.snapshot {
                        VStack(alignment: .leading) { snapshotnum }
                    }

                    Section(header: Text("Show save URL")
                        .font(.title3)
                        .fontWeight(.bold)) {
                            HStack {
                                Toggle("", isOn: $newdata.showsaveurls)
                                    .toggleStyle(.switch)

                                if newdata.showsaveurls {
                                    HStack {
                                        ConditionalGlassButton(
                                            systemImage: "square.and.arrow.down",
                                            text: "URL Estimate",
                                            helpText: "URL Estimate & Synchronize"
                                        ) {
                                            let data = WidgetURLstrings(urletimate: stringestimate)
                                            WriteWidgetsURLStringsJSON(data)
                                        }
                                    }
                                }
                            }
                        }
                }

                // Column 2
                VStack(alignment: .leading) {
                    if deleteparameterpresent {
                        HStack {
                            Text("If \(Text("red Synchronize ID").foregroundColor(.red)) click")

                            Button {
                                newdata.whichhelptext = 1
                                showhelp = true
                            } label: {
                                Image(systemName: "questionmark.circle")
                            }
                            .buttonStyle(HelpButtonStyle(redorwhitebutton: deleteparameterpresent))

                            Text("for more information")
                        }
                        .padding(.bottom, 10)

                    } else {
                        HStack {
                            Text("To add --delete click")

                            Button {
                                newdata.whichhelptext = 2
                                showhelp = true
                            } label: {
                                Image(systemName: "questionmark.circle")
                            }
                            .buttonStyle(HelpButtonStyle(redorwhitebutton: deleteparameterpresent))

                            Text("for more information")
                        }
                        .padding(.bottom, 10)
                    }

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
                                        // Create estimate and synchronize URL
                                        let urlestimate = deeplinkurl.createURLestimateandsynchronize(valueprofile: rsyncUIdata.profile ?? "Default")
                                        stringestimate = urlestimate?.absoluteString ?? ""

                                    } else {
                                        stringestimate = ""
                                    }

                                } else {
                                    selectedconfig = nil
                                    newdata.updateview(nil)
                                    // URL String
                                    stringestimate = ""
                                    newdata.showsaveurls = false
                                }
                            }
                        }
                        .copyable(copyitems.filter { selecteduuids.contains($0.id) })
                        .pasteDestination(for: CopyItem.self) { items in
                            newdata.prepareCopyAndPasteTasks(items,
                                                             rsyncUIdata.configurations ?? [])
                            guard items.count > 0 else { return }
                            confirmcopyandpaste = true
                        } validator: { items in
                            items.filter { $0.task != SharedReference.shared.snapshot }
                        }
                        .confirmationDialog(newdata.copyandpasteconfigurations?.count ?? 0 == 1 ? "Copy 1 configuration" :
                            "Copy \(newdata.copyandpasteconfigurations?.count ?? 0) configurations",
                            isPresented: $confirmcopyandpaste) {
                                Button("Copy") {
                                    confirmcopyandpaste = false
                                    rsyncUIdata.configurations =
                                        newdata.writeCopyAndPasteTasks(rsyncUIdata.profile,
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
        .sheet(isPresented: $showhelp) {
            switch newdata.whichhelptext {
            case 1:
                HelpView(text: newdata.helptext1, add: false, deleteparameterpresent: false)
            case 2:
                HelpView(text: newdata.helptext2, add: false, deleteparameterpresent: false)
            default:
                HelpView(text: newdata.helptext1, add: false, deleteparameterpresent: false)
            }
        }
        .onSubmit {
            switch focusField {
            case .synchronizeIDField:
                focusField = .localcatalogField
            case .localcatalogField:
                focusField = .remotecatalogField
            case .remotecatalogField:
                focusField = .remoteuserField
            case .remoteuserField:
                focusField = .remoteserverField
            case .snapshotnumField:
                validateAndUpdate()
            case .remoteserverField:
                if newdata.selectedconfig == nil {
                    addConfig()
                } else {
                    validateAndUpdate()
                }
                focusField = nil
            default:
                return
            }
        }
        .onAppear {
            if selecteduuids.count > 0 {
                // Reset preselected tasks, must do a few seconds timout
                // before clearing it out
                Task {
                    try await Task.sleep(seconds: 2)
                    selecteduuids.removeAll()
                }
            }
        }
        .onChange(of: rsyncUIdata.profile) {
            newdata.resetForm()
            selecteduuids.removeAll()
            selectedconfig = nil
        }
        .toolbar {
            ToolbarItem {
                Button {
                    addtaskpath.append(AddTasks(task: .homecatalogs))
                } label: {
                    Image(systemName: "house.fill")
                }
                .help("Home catalogs")
            }

            ToolbarItem {
                Button {
                    addtaskpath.append(AddTasks(task: .globalchanges))
                } label: {
                    Image(systemName: "globe")
                }
                .help("Global change and update")
            }
        }
        .navigationTitle("Add and update tasks: profile \(rsyncUIdata.profile ?? "Default")")
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
                             path: $addtaskpath,
                             homecatalogs: HomeCatalogsService().homeCatalogs(),
                             attachedVolumes: AttachedVolumesService().attachedVolumes())

        case .globalchanges:
            GlobalChangeTaskView(rsyncUIdata: rsyncUIdata)
        }
    }

    // Add and edit text values
    var setlocalcatalogsyncremote: some View {
        EditValueScheme(300, NSLocalizedString("Add Remote folder - required", comment: ""),
                        $newdata.localcatalog)
            .focused($focusField, equals: .localcatalogField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var setremotecatalogsyncremote: some View {
        EditValueScheme(300, NSLocalizedString("Add Source folder - required", comment: ""),
                        $newdata.remotecatalog)
            .focused($focusField, equals: .remotecatalogField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var setlocalcatalog: some View {
        EditValueScheme(300, NSLocalizedString("Add Source folder - required", comment: ""),
                        $newdata.localcatalog)
            .focused($focusField, equals: .localcatalogField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var setremotecatalog: some View {
        EditValueScheme(300, NSLocalizedString("Add Destination folder - required", comment: ""),
                        $newdata.remotecatalog)
            .focused($focusField, equals: .remotecatalogField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    // Headers (in sections)
    var headerlocalremote: some View {
        Text("Folder parameters")
            .modifier(FixedTag(200, .leading))
            .font(.title3)
            // .foregroundColor(.blue)
            .fontWeight(.bold)
    }

    var localandremotecatalog: some View {
        Section(header: headerlocalremote) {
            HStack {
                // localcatalog
                if newdata.selectedconfig == nil { setlocalcatalog } else {
                    EditValueScheme(300, nil, $newdata.localcatalog)
                        .focused($focusField, equals: .localcatalogField)
                        .textContentType(.none)
                        .submitLabel(.continue)
                        .onAppear {
                            if let catalog = newdata.selectedconfig?.localCatalog {
                                newdata.localcatalog = catalog
                            }
                        }
                }
                OpencatalogView(selecteditem: $newdata.localcatalog, catalogs: true)
            }
            HStack {
                // remotecatalog
                if newdata.selectedconfig == nil { setremotecatalog } else {
                    EditValueScheme(300, nil, $newdata.remotecatalog)
                        .focused($focusField, equals: .remotecatalogField)
                        .textContentType(.none)
                        .submitLabel(.continue)
                        .onAppear {
                            if let catalog = newdata.selectedconfig?.offsiteCatalog {
                                newdata.remotecatalog = catalog
                            }
                        }
                }
                OpencatalogView(selecteditem: $newdata.remotecatalog, catalogs: true)
            }
        }
    }

    var localandremotecatalogsyncremote: some View {
        Section(header: headerlocalremote) {
            HStack {
                // remotecatalog
                if newdata.selectedconfig == nil { setremotecatalogsyncremote } else {
                    EditValueScheme(300, nil, $newdata.remotecatalog)
                        .focused($focusField, equals: .remotecatalogField)
                        .textContentType(.none)
                        .submitLabel(.continue)
                        .onAppear {
                            if let catalog = newdata.selectedconfig?.offsiteCatalog {
                                newdata.remotecatalog = catalog
                            }
                        }
                }
                OpencatalogView(selecteditem: $newdata.remotecatalog, catalogs: true)
            }

            HStack {
                // localcatalog
                if newdata.selectedconfig == nil { setlocalcatalogsyncremote } else {
                    EditValueScheme(300, nil, $newdata.localcatalog)
                        .focused($focusField, equals: .localcatalogField)
                        .textContentType(.none)
                        .submitLabel(.continue)
                        .onAppear {
                            if let catalog = newdata.selectedconfig?.localCatalog {
                                newdata.localcatalog = catalog
                            }
                        }
                }
                OpencatalogView(selecteditem: $newdata.localcatalog, catalogs: true)
            }
        }
    }

    var setID: some View {
        EditValueScheme(300, NSLocalizedString("Add synchronize ID", comment: ""),
                        $newdata.backupID)
            .focused($focusField, equals: .synchronizeIDField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var headerID: some View {
        Text("Synchronize ID")
            .modifier(FixedTag(200, .leading))
            .font(.title3)
            // .foregroundColor(.blue)
            .fontWeight(.bold)
    }

    var synchronizeID: some View {
        Section(header: headerID) {
            // Synchronize ID
            if newdata.selectedconfig == nil { setID } else {
                EditValueScheme(300, nil, $newdata.backupID)
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
    }

    var snapshotnumheader: some View {
        Text("Snapshotnumber")
            .modifier(FixedTag(200, .leading))
    }

    var snapshotnum: some View {
        Section(header: snapshotnumheader) {
            // Reset snapshotnum
            EditValueScheme(300, nil, $newdata.snapshotnum)
                .focused($focusField, equals: .snapshotnumField)
                .textContentType(.none)
                .submitLabel(.return)
                .disabled(!changesnapshotnum)

            ToggleViewDefault(text: NSLocalizedString("Change snapshotnumber", comment: ""),
                              binding: $changesnapshotnum)
        }
    }

    var setremoteuser: some View {
        EditValueScheme(300, NSLocalizedString("Add remote user", comment: ""),
                        $newdata.remoteuser)
            .focused($focusField, equals: .remoteuserField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var setremoteserver: some View {
        EditValueScheme(300, NSLocalizedString("Add remote server", comment: ""),
                        $newdata.remoteserver)
            .focused($focusField, equals: .remoteserverField)
            .textContentType(.none)
            .submitLabel(.return)
    }

    var headerremote: some View {
        Text("Remote parameters")
            .modifier(FixedTag(200, .leading))
            .font(.title3)
            // .foregroundColor(.blue)
            .fontWeight(.bold)
    }

    var remoteuserandserver: some View {
        Section(header: headerremote) {
            // Remote user
            if newdata.selectedconfig == nil { setremoteuser } else {
                EditValueScheme(300, nil, $newdata.remoteuser)
                    .focused($focusField, equals: .remoteuserField)
                    .textContentType(.none)
                    .submitLabel(.continue)
                    .onAppear {
                        if let user = newdata.selectedconfig?.offsiteUsername {
                            newdata.remoteuser = user
                        }
                    }
            }
            // Remote server
            if newdata.selectedconfig == nil { setremoteserver } else {
                EditValueScheme(300, nil, $newdata.remoteserver)
                    .focused($focusField, equals: .remoteserverField)
                    .textContentType(.none)
                    .submitLabel(.return)
                    .onAppear {
                        if let server = newdata.selectedconfig?.offsiteServer {
                            newdata.remoteserver = server
                        }
                    }
            }
        }
    }

    var trailingslash: some View {
        Picker(NSLocalizedString("Trailing /", comment: ""),
               selection: $newdata.trailingslashoptions) {
            ForEach(TrailingSlash.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 180)
        .onChange(of: newdata.trailingslashoptions) {
            // Saving selected trailing slash as default value in UserDefaults
            UserDefaults.standard.set(newdata.trailingslashoptions.rawValue, forKey: "trailingslashoptions")
        }
        .onAppear {
            if let trailingslashoptions = UserDefaults.standard.value(forKey: "trailingslashoptions") {
                guard let trailing = trailingslashoptions as? String else { return }
                switch trailing {
                case "do_not_check":
                    newdata.trailingslashoptions = TrailingSlash.do_not_check
                case "do_not_add":
                    newdata.trailingslashoptions = TrailingSlash.do_not_add
                case "add":
                    newdata.trailingslashoptions = TrailingSlash.add
                default:
                    newdata.trailingslashoptions = TrailingSlash.add
                }
            }
        }
    }

    var pickerselecttypeoftask: some View {
        Picker(NSLocalizedString("Action", comment: ""),
               selection: $newdata.selectedrsynccommand) {
            ForEach(TypeofTask.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 180)
        .onChange(of: newdata.selectedrsynccommand) {
            // Saving selected rsync command slash as default value in UserDefaults
            UserDefaults.standard.set(newdata.selectedrsynccommand.rawValue, forKey: "selectedrsynccommand")
        }
        .onAppear {
            if let selectedrsynccommand = UserDefaults.standard.value(forKey: "selectedrsynccommand") {
                switch selectedrsynccommand as? String {
                case "synchronize":
                    newdata.selectedrsynccommand = TypeofTask.synchronize
                case "snapshot":
                    newdata.selectedrsynccommand = TypeofTask.snapshot
                case "syncremote":
                    newdata.selectedrsynccommand = TypeofTask.syncremote
                default:
                    newdata.selectedrsynccommand = TypeofTask.synchronize
                }
            }
        }
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

    var deleteparameterpresent: Bool {
        let parameter = rsyncUIdata.configurations?.filter { $0.parameter4.isEmpty == false }
        return parameter?.count ?? 0 > 0
    }
}

extension AddTaskView {
    func addConfig() {
        let profile = rsyncUIdata.profile
        rsyncUIdata.configurations = newdata.addConfig(profile, rsyncUIdata.configurations)
        if SharedReference.shared.duplicatecheck {
            if let configurations = rsyncUIdata.configurations {
                VerifyDuplicates(configurations)
            }
        }
    }

    func validateAndUpdate() {
        let profile = rsyncUIdata.profile
        rsyncUIdata.configurations = newdata.updateConfig(profile, rsyncUIdata.configurations)
        selecteduuids.removeAll()
    }
}
