//
//  GlobalChangeTaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/11/2024.
//

import SwiftUI

struct GlobalChangeTaskView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @State private var newdata = ObservableGlobalchangeConfigurations()
    @State private var updated: Bool = false
    // Alert button
    @State private var showingAlert = false
    // Focusfield
    @FocusState private var focusField: AddConfigurationField?
    
    var body: some View {
        HStack {
            // Column 1
            VStack(alignment: .leading) {
                VStack(alignment: .leading) { synchronizeID }

                VStack(alignment: .leading) { localandremotecatalog }

                VStack(alignment: .leading) { remoteuserandserver }

                Spacer()
            }
            .padding()

            // Column 2
            VStack(alignment: .leading) {
                Table(configurations) {
                    TableColumn("Synchronize ID (1)") { data in
                        if data.backupID.isEmpty == true {
                            Text("Synchronize ID")
                        } else {
                            Text(data.backupID)
                        }
                    }
                    .width(min: 50, max: 150)
                    TableColumn("Local catalog (2)") { data in
                        if newdata.occurence_localcatalog.isEmpty == false && newdata.occurence_localcatalog.contains("$") {
                            Text(newdata.splitinput(input: newdata.occurence_localcatalog, original: data.localCatalog))
                        } else {
                            Text(data.localCatalog)
                        }
                    }
                        .width(min: 180, max: 300)
                    TableColumn("Remote catalog (3)", value: \.offsiteCatalog)
                        .width(min: 180, max: 300)
                    TableColumn("Remote user (4)", value: \.offsiteUsername)
                        .width(min: 100, max: 150)
                    TableColumn("Server (5)", value: \.offsiteServer)
                }
                .overlay {
                    if configurations.isEmpty {
                        ContentUnavailableView {
                            Label("Most likely, you try to update snapshot tasks, not allowed.",
                                  systemImage: "doc.richtext.fill")
                        } description: {
                            Text("Or there are no tasks to update.")
                        }
                    }
                }
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Update all configurations?"),
                primaryButton: .default(Text("Update")) {
                    // any snapshotstasks
                    if let snapshotstask = newdata.notchangedsnapshotconfigurations,
                       let globalupdate = newdata.globalchangedconfigurations
                    {
                        rsyncUIdata.configurations = globalupdate + snapshotstask
                    } else {
                        rsyncUIdata.configurations = newdata.globalchangedconfigurations
                    }
                    WriteSynchronizeConfigurationJSON(rsyncUIdata.profile, rsyncUIdata.configurations)
                },
                secondaryButton: .cancel {
                    newdata.globalchangedconfigurations = rsyncUIdata.configurations
                }
            )
        }
        .toolbar(content: {
            ToolbarItem {
                Button {
                    guard newdata.whatischanged.isEmpty == false else { return }
                    newdata.updateglobalchangedconfigurations()
                    showingAlert = true
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
                .disabled(configurations.isEmpty)
            }
        })
        .padding()
        .onAppear {
            // Synchronize and syncremote tasks
            newdata.globalchangedconfigurations = rsyncUIdata.configurations?.compactMap { task in
                (task.task != SharedReference.shared.snapshot) ? task : nil
            }
            // Snapshot tasks
            newdata.notchangedsnapshotconfigurations = rsyncUIdata.configurations?.compactMap { task in
                (task.task == SharedReference.shared.snapshot) ? task : nil
            }
        }
        .onChange(of: newdata.whatischanged) {
            updated = !newdata.whatischanged.isEmpty
        }
        .onSubmit {
            switch focusField {
            case .localcatalogField:
                newdata.updateglobalchangedconfigurations()
                showingAlert = true
            case .remotecatalogField:
                newdata.updateglobalchangedconfigurations()
                showingAlert = true
            case .remoteuserField:
                newdata.updateglobalchangedconfigurations()
                showingAlert = true
            case .remoteserverField:
                newdata.updateglobalchangedconfigurations()
                showingAlert = true
            case .synchronizeIDField:
                newdata.updateglobalchangedconfigurations()
                showingAlert = true
            default:
                return
            }
        }
    }

    var localandremotecatalog: some View {
        Section(header: headerlocalremote) {
            // localcatalog
            EditValue(300, NSLocalizedString("Global change local catalog (2)", comment: ""), $newdata.occurence_localcatalog)
                .onChange(of: newdata.occurence_localcatalog) {
                    Task {
                        try await Task.sleep(seconds: 2)
                        if newdata.occurence_localcatalog.isEmpty {
                            if newdata.whatischanged.contains(.localcatalog) {
                                newdata.whatischanged.remove(.localcatalog)
                            }
                        } else {
                            if newdata.whatischanged.contains(.localcatalog) == false {
                                newdata.whatischanged.insert(.localcatalog)
                            }
                        }
                    }
                }
                .disabled(configurations.isEmpty)
                .focused($focusField, equals: .localcatalogField)

            EditValue(300, NSLocalizedString("Global change remote catalog (3)", comment: ""), $newdata.occurence_remotecatalog)
                .onChange(of: newdata.occurence_remotecatalog) {
                    Task {
                        try await Task.sleep(seconds: 2)
                        if newdata.occurence_remotecatalog.isEmpty {
                            if newdata.whatischanged.contains(.remotecatalog) {
                                newdata.whatischanged.remove(.remotecatalog)
                            }
                        } else {
                            if newdata.whatischanged.contains(.remotecatalog) == false {
                                newdata.whatischanged.insert(.remotecatalog)
                            }
                        }
                    }
                }
                .disabled(configurations.isEmpty)
                .focused($focusField, equals: .remotecatalogField)
        }
    }

    var remoteuserandserver: some View {
        Section(header: headerremote) {
            // Remote user
            EditValue(300, NSLocalizedString("Global change remote user (4)", comment: ""), $newdata.occurence_remoteuser)
                .onChange(of: newdata.occurence_remoteuser) {
                    Task {
                        try await Task.sleep(seconds: 2)
                        if newdata.occurence_remoteuser.isEmpty {
                            if newdata.whatischanged.contains(.remoteuser) {
                                newdata.whatischanged.remove(.remoteuser)
                            }
                        } else {
                            if newdata.whatischanged.contains(.remoteuser) == false {
                                newdata.whatischanged.insert(.remoteuser)
                            }
                        }
                    }
                }
                .disabled(configurations.isEmpty)
                .focused($focusField, equals: .remoteuserField)

            // Remote server
            EditValue(300, NSLocalizedString("Global change remote server (5)", comment: ""), $newdata.occurence_remoteserver)
                .onChange(of: newdata.occurence_remoteserver) {
                    Task {
                        try await Task.sleep(seconds: 2)
                        if newdata.occurence_remoteserver.isEmpty {
                            if newdata.whatischanged.contains(.remoteserver) {
                                newdata.whatischanged.remove(.remoteserver)
                            }
                        } else {
                            if newdata.whatischanged.contains(.remoteserver) == false {
                                newdata.whatischanged.insert(.remoteserver)
                            }
                        }
                    }
                }
                .disabled(configurations.isEmpty)
                .focused($focusField, equals: .remoteserverField)
        }
    }

    var synchronizeID: some View {
        Section(header: headerID) {
            // Synchronize ID
            EditValue(300, NSLocalizedString("Global change Synchronize ID (1)", comment: ""), $newdata.occurence_backupID)
                .onChange(of: newdata.occurence_backupID) {
                    Task {
                        try await Task.sleep(seconds: 2)
                        if newdata.occurence_backupID.isEmpty {
                            if newdata.whatischanged.contains(.backupID) {
                                newdata.whatischanged.remove(.backupID)
                            }
                        } else {
                            if newdata.whatischanged.contains(.backupID) == false {
                                newdata.whatischanged.insert(.backupID)
                            }
                        }
                    }
                }
                .disabled(configurations.isEmpty)
                .focused($focusField, equals: .synchronizeIDField)
        }
    }

    // Headers (in sections)
    var headerlocalremote: some View {
        Text("Catalog parameters")
            .modifier(FixedTag(200, .leading))
    }

    var headerremote: some View {
        Text("Remote parameters")
            .modifier(FixedTag(200, .leading))
    }

    var headerID: some View {
        Text("Synchronize ID")
            .modifier(FixedTag(200, .leading))
    }

    var configurations: [SynchronizeConfiguration] {
        if let configurations = newdata.globalchangedconfigurations {
            configurations
        } else {
            []
        }
    }
}
