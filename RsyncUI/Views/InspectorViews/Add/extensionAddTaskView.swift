//
//  extensionAddTaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 13/12/2025.
//
// swiftlint:disable file_length
import OSLog
import SwiftUI

// MARK: - Configuration Actions

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
        // Reset after Update
        clearSelection()
    }
}

// MARK: - View Builders

extension AddTaskView {
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

// MARK: - Buttons

extension AddTaskView {
    var addButton: some View {
        ConditionalGlassButton(systemImage: "plus", text: "Add", helpText: "Add task") {
            addConfig()
        }
    }

    var updateButton: some View {
        ConditionalGlassButton(systemImage: "arrow.down", text: "Update", helpText: "Update task") {
            validateAndUpdate()
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
}

// MARK: - Help & Toolbar

extension AddTaskView {
    var helpSheetView: some View {
        switch newdata.whichhelptext {
        case 1: HelpView(text: newdata.helptext1, add: false, deleteparameterpresent: false)
        case 2: HelpView(text: newdata.helptext2, add: false, deleteparameterpresent: false)
        default: HelpView(text: newdata.helptext1, add: false, deleteparameterpresent: false)
        }
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        if selectedconfig != nil {
            ToolbarItem {
                Button {
                    showcommand.toggle()
                } label: {
                    Image(systemName: "command")
                }
                .help("Show rsync command")
            }
        }

        ToolbarItem {
            Button {
                newdata.resetForm()
                selectedconfig = nil
                showAddPopover.toggle()
            }
            label: { Image(systemName: "plus") }
            .help("Quick add task")
            .sheet(isPresented: $showAddPopover) { addTaskSheetView }
        }

        ToolbarItem {
            Button { presentglobaltaskview = true }
                label: { Image(systemName: "globe") }
                .help("Global change and update")
        }

        ToolbarItem {
            ToggleViewToolbar(text: "Tasks",
                              binding: $togglechooseview)
        }

        ToolbarItem {
            Spacer()
        }
    }
}

// MARK: - Task List & Inspector Views

extension AddTaskView {
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
                    showAddPopover = false
                    newdata.resetForm()
                }.disabled(disableadd)

                Spacer()

                if #available(macOS 26.0, *) {
                    Button("Close", role: .close) {
                        showAddPopover = false
                    }
                    .buttonStyle(RefinedGlassButtonStyle())
                    .keyboardShortcut(.cancelAction)

                } else {
                    Button {
                        showAddPopover = false
                    } label: {
                        Image(systemName: "return")
                    }
                    .help("Close")
                    .keyboardShortcut(.cancelAction)
                }
            }
        }
        .padding()
        .frame(minWidth: 500)
        .onSubmit { handleSubmit() }
    }

    // Disable the Add+ button
    var disableadd: Bool {
        // Both catalogs must be provided
        if newdata.localcatalog.isEmpty && newdata.remotecatalog.isEmpty {
            return true
        }
        // Can't have remoteuser without remoteserver
        if newdata.remoteuser.isEmpty == false && newdata.remoteserver.isEmpty {
            return true
        }
        // Can't have remoteserver without remoteuser
        if newdata.remoteuser.isEmpty && newdata.remoteserver.isEmpty == false {
            return true
        }
        // For syncremote command, both remoteuser AND remoteserver are required
        if newdata.selectedrsynccommand.rawValue == "syncremote" &&
            (newdata.remoteuser.isEmpty || newdata.remoteserver.isEmpty) {
            return true
        }
        return false
    }

    var taskListView: some View {
        ListofTasksAddView(rsyncUIdata: rsyncUIdata, selecteduuids: $selecteduuids)
            .onChange(of: selecteduuids) { handleSelectionChange() }
            .copyable(copyitems.filter { selecteduuids.contains($0.id) })
            .pasteDestination(for: CopyItem.self) { handlePaste($0) }
            validator: { $0.filter { $0.task != SharedReference.shared.snapshot } }
            .confirmationDialog(confirmationMessage, isPresented: $confirmcopyandpaste) {
                Button("Copy") { handleCopyConfirmation() }
            }
    }

    var confirmationMessage: String {
        let count = newdata.copyandpasteconfigurations?.count ?? 0
        return count == 1 ? "Copy 1 configuration" : "Copy \(count) configurations"
    }

    var inspectorView: some View {
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

    @ViewBuilder
    func inspectorSummary(_ config: SynchronizeConfiguration) -> some View {
        HStack {
            updateButton

            VStack(alignment: .leading, spacing: 4) {
                Text(config.backupID).font(.headline)
                Text(config.task).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Form Field Sections

extension AddTaskView {
    var synchronizeID: some View {
        Section(header: Text("Synchronize ID").modifier(FixedTag(200, .leading)).font(.title3).fontWeight(.bold)) {
            if newdata.selectedconfig == nil {
                EditValueScheme(300, "Add synchronize ID", $newdata.backupID)
                    .focused($focusField, equals: .synchronizeIDField)
                    .textContentType(.none).submitLabel(.continue)
            } else {
                EditValueScheme(300, nil, $newdata.backupID)
                    .focused($focusField, equals: .synchronizeIDField)
                    .textContentType(.none).submitLabel(.continue)
                    .onAppear { if let id = newdata.selectedconfig?.backupID { newdata.backupID = id } }
            }
        }
    }

    var snapshotnum: some View {
        Section(header: Text("Snapshotnumber").modifier(FixedTag(200, .leading))) {
            EditValueScheme(300, nil, $newdata.snapshotnum)
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
                         selectedValue: newdata.selectedconfig?.offsiteCatalog)
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
                         selectedValue: newdata.selectedconfig?.localCatalog)
        }
    }

    func catalogField(catalog: Binding<String>, placeholder: String,
                      focus: AddConfigurationField, selectedValue: String?) -> some View {
        HStack {
            if newdata.selectedconfig == nil {
                EditValueScheme(300, placeholder, catalog)
                    .focused($focusField, equals: focus)
                    .textContentType(.none).submitLabel(.continue)
            } else {
                EditValueScheme(300, nil, catalog)
                    .focused($focusField, equals: focus)
                    .textContentType(.none).submitLabel(.continue)
                    .onAppear { if let value = selectedValue { catalog.wrappedValue = value } }
            }
            OpencatalogView(selecteditem: catalog, catalogs: true)
        }
    }

    var remoteuserandserver: some View {
        Section(header: Text("Remote parameters").modifier(FixedTag(200, .leading)).font(.title3).fontWeight(.bold)) {
            remoteField(value: $newdata.remoteuser, placeholder: "Add remote user",
                        focus: .remoteuserField, selectedValue: newdata.selectedconfig?.offsiteUsername)
            remoteField(value: $newdata.remoteserver, placeholder: "Add remote server",
                        focus: .remoteserverField, selectedValue: newdata.selectedconfig?.offsiteServer,
                        submitLabel: .return)
        }
    }

    func remoteField(value: Binding<String>, placeholder: String, focus: AddConfigurationField,
                     selectedValue: String?, submitLabel: SubmitLabel = .continue) -> some View {
        Group {
            if newdata.selectedconfig == nil {
                EditValueScheme(300, placeholder, value)
                    .focused($focusField, equals: focus)
                    .textContentType(.none).submitLabel(submitLabel)
            } else {
                EditValueScheme(300, nil, value)
                    .focused($focusField, equals: focus)
                    .textContentType(.none).submitLabel(submitLabel)
                    .onAppear { if let val = selectedValue { value.wrappedValue = val } }
            }
        }
    }
}

// MARK: - Picker Controls

extension AddTaskView {
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

// MARK: - Business Logic & User Actions

extension AddTaskView {
    func clearSelection() {
        selecteduuids.removeAll()
        selectedconfig = nil
        newdata.updateview(nil)
        newdata.showsaveurls = false
        changesnapshotnum = false
        stringestimate = ""
    }

    func handleSubmit() {
        switch focusField {
        case .synchronizeIDField: focusField = .localcatalogField
        case .localcatalogField: focusField = .remotecatalogField
        case .remotecatalogField: focusField = .remoteuserField
        case .remoteuserField: focusField = .remoteserverField
        case .snapshotnumField: validateAndUpdate()
        case .remoteserverField:
            if newdata.selectedconfig == nil { addConfig() } else { validateAndUpdate() }
            focusField = nil
        default: return
        }
    }

    func handleOnAppear() {
        if selecteduuids.count > 0 {
            Task {
                try await Task.sleep(seconds: 2)
                selecteduuids.removeAll()
            }
        }
    }

    func handleProfileChange() {
        newdata.resetForm()
        selecteduuids.removeAll()
        selectedconfig = nil
    }

    func handleSelectionChange() {
        if let configurations = rsyncUIdata.configurations {
            if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                selectedconfig = configurations[index]
                newdata.updateview(configurations[index])
                updateURLString()
                showinspector = true
            } else {
                selectedconfig = nil
                newdata.updateview(nil)
                stringestimate = ""
                newdata.showsaveurls = false
                showinspector = false
            }
        }
    }

    func updateURLString() {
        if selectedconfig?.task == SharedReference.shared.synchronize {
            let deeplinkurl = DeeplinkURL()
            let urlestimate = deeplinkurl.createURLestimateandsynchronize(valueprofile: rsyncUIdata.profile ?? "Default")
            stringestimate = urlestimate?.absoluteString ?? ""
        } else {
            stringestimate = ""
        }
    }

    func handlePaste(_ items: [CopyItem]) {
        newdata.prepareCopyAndPasteTasks(items, rsyncUIdata.configurations ?? [])
        guard items.count > 0 else { return }
        confirmcopyandpaste = true
    }

    func handleCopyConfirmation() {
        confirmcopyandpaste = false
        rsyncUIdata.configurations = newdata.writeCopyAndPasteTasks(rsyncUIdata.profile, rsyncUIdata.configurations ?? [])
        if SharedReference.shared.duplicatecheck, let configurations = rsyncUIdata.configurations {
            VerifyDuplicates(configurations)
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
}

// MARK: - Computed Properties

extension AddTaskView {
    var copyitems: [CopyItem] {
        rsyncUIdata.configurations?.map { CopyItem(id: $0.id, task: $0.task) } ?? []
    }

    var deleteparameterpresent: Bool {
        (rsyncUIdata.configurations?.filter { $0.parameter4?.isEmpty == false }.count ?? 0) > 0
    }
}

// swiftlint:enable file_length
