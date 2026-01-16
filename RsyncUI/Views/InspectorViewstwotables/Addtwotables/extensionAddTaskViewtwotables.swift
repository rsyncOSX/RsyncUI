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

extension AddTaskViewtwotables {
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

extension AddTaskViewtwotables {
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

extension AddTaskViewtwotables {
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

extension AddTaskViewtwotables {
    var helpSheetView: some View {
        switch newdata.whichhelptext {
        case 1: HelpView(text: newdata.helptext1, add: false, deleteparameterpresent: false)
        case 2: HelpView(text: newdata.helptext2, add: false, deleteparameterpresent: false)
        default: HelpView(text: newdata.helptext1, add: false, deleteparameterpresent: false)
        }
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        // Only show toolbar items when this tab is active
        if selectedTab == .edit {
            ToolbarItem {
                Button {
                    showinspector = false
                    newdata.resetForm()
                    selectedconfig = nil
                    showAddPopover.toggle()
                }
                label: { Image(systemName: "plus") }
                .help("Quick add task")
                .sheet(isPresented: $showAddPopover) { addTaskSheetView }
            }

            ToolbarItem {
                Spacer()
            }
        }
    }
}

// MARK: - Task List & Inspector Views

extension AddTaskViewtwotables {
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
                }.disabled(!disableadd)

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
        .frame(minWidth: 600)
        .onSubmit { handleSubmit() }
    }

    // The verify returns true when data is OK
    var disableadd: Bool {
        VerifyObservableAddConfiguration(observed: newdata).verify()
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
}

// MARK: - Form Field Sections

extension AddTaskViewtwotables {
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
            remoteField(value: $newdata.remoteuser, placeholder: "Add remote user",
                        focus: .remoteuserField, selectedValue: newdata.selectedconfig?.offsiteUsername,
                        showErrorBorder: newdata.remoteuser.isEmpty && !newdata.remoteserver.isEmpty)
            remoteField(value: $newdata.remoteserver, placeholder: "Add remote server",
                        focus: .remoteserverField, selectedValue: newdata.selectedconfig?.offsiteServer,
                        submitLabel: .return,
                        showErrorBorder: !newdata.remoteuser.isEmpty && newdata.remoteserver.isEmpty)
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
}

// MARK: - Picker Controls

extension AddTaskViewtwotables {
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

extension AddTaskViewtwotables {
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

    func handleProfileChange() {
        newdata.resetForm()
        selecteduuids.removeAll()
        selectedconfig = nil
    }

    func handleSelectionChange() {
        if let configurations = rsyncUIdata.configurations {
            guard selecteduuids.count == 1 else {
                showinspector = false
                return
            }
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

extension AddTaskViewtwotables {
    var copyitems: [CopyItem] {
        rsyncUIdata.configurations?.map { CopyItem(id: $0.id, task: $0.task) } ?? []
    }

    var deleteparameterpresent: Bool {
        (rsyncUIdata.configurations?.filter { $0.parameter4?.isEmpty == false }.count ?? 0) > 0
    }
}

// swiftlint:enable file_length
