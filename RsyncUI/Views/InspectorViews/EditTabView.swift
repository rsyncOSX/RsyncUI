//
//  TasksOverview.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 28/12/2025.
//

import SwiftUI

struct EditTabView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var notasks: Bool = false

    @State var showAddPopover: Bool = false
    @State var newdata = ObservableAddConfigurations()
    
    /// Focusfield
    @FocusState private var focusField: AddConfigurationField?

    /// The verify returns true when data is OK
    var disableadd: Bool {
        VerifyObservableAddConfiguration(observed: newdata).verify()
    }
    
    func addConfig() {
        let profile = rsyncUIdata.profile
        rsyncUIdata.configurations = newdata.addConfig(profile, rsyncUIdata.configurations)
        if SharedReference.shared.duplicatecheck {
            if let configurations = rsyncUIdata.configurations {
                VerifyDuplicates(configurations)
            }
        }
    }

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
            }
        }
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
        .onSubmit { addConfig() }
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button {
                newdata.resetForm()
                showAddPopover.toggle()
            }
            label: { Image(systemName: "plus") }
            .help("Quick add task")
            .sheet(isPresented: $showAddPopover) { addTaskSheetView }
        }
    }
    
    var body: some View {
        HStack {
            if notasks {
                HStack {
                    
                    AddFirstTask(rsyncUIdata: rsyncUIdata)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("For your own safety, please read the user doc\n")
                            + Text("Getting Started").bold()
                            + Text(", ")
                            + Text("Important").bold()
                            + Text(" about the ")
                            + Text("--delete").font(.system(.body, design: .monospaced))
                            + Text(" parameter.\n")

                        Text("The ")
                            + Text("--delete").font(.system(.body, design: .monospaced))
                            + Text(" parameter is disabled by default.\n")

                        Text("If Synchronize ID is ")
                            + Text("blue").foregroundColor(.blue)
                            + Text(" the parameter is disabled.\n")

                        Text("If the Synchronize ID is ")
                            + Text("red").foregroundColor(.red)
                            + Text(" parameter is enabled.")
                    }
                    .padding()
                    .font(.title2)
                }
            } else {
                // Shared task list table on the left
                ListofTasksAddView(
                    rsyncUIdata: rsyncUIdata,
                    selecteduuids: $selecteduuids
                )
                .frame(minWidth: 300)
                .onChange(of: rsyncUIdata.profile) {
                    selecteduuids.removeAll()
                }
                
            }
        }
        .task(id: rsyncUIdata.configurations) {
            if let config = rsyncUIdata.configurations, config.isEmpty {
                notasks = true
            } else {
                notasks = false
            }
        }
        .inspector(isPresented: Binding(
            get: { !notasks },
            set: { notasks = !$0 }
        )) {
            InspectorView(rsyncUIdata: rsyncUIdata, selecteduuids: $selecteduuids)
        }
        .toolbar { toolbarContent }

    }
}
