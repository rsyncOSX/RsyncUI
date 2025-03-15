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
    // Alert button
    @State private var showingAlert = false
    // Focusfield
    @FocusState private var focusField: AddConfigurationField?

    var body: some View {
        HStack {
            // Column 1

            VStack(alignment: .leading) {
                Text("Use $ as split character")
                    .padding(.vertical, 2)

                VStack(alignment: .leading) { synchronizeID }

                VStack(alignment: .leading) { localandremotecatalog }

                VStack(alignment: .leading) { remoteuserandserver }

                Spacer()
            }
            .padding()

            // Column 2
            VStack(alignment: .leading) {
                ConfigurationsTableGlobalChanges(newdata: $newdata)
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
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(.blue))
                }
                .help("Update task")
                .disabled(configurations.isEmpty)
            }
        })
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
            EditValue(300, NSLocalizedString("Local catalog", comment: ""), $newdata.occurence_localcatalog)
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

            EditValue(300, NSLocalizedString("Remote catalog", comment: ""), $newdata.occurence_remotecatalog)
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
            EditValue(300, NSLocalizedString("Remote user", comment: ""), $newdata.occurence_remoteuser)
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
            EditValue(300, NSLocalizedString("Remote server", comment: ""), $newdata.occurence_remoteserver)
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
            EditValue(300, NSLocalizedString("Synchronize ID", comment: ""), $newdata.occurence_backupID)
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
        Text("Catalog parameters - split character $")
            .modifier(FixedTag(300, .leading))
    }

    var headerremote: some View {
        Text("Remote parameters - replace string")
            .modifier(FixedTag(300, .leading))
    }

    var headerID: some View {
        Text("Synchronize ID - split character $")
            .modifier(FixedTag(300, .leading))
    }

    var configurations: [SynchronizeConfiguration] {
        if let configurations = newdata.globalchangedconfigurations {
            configurations
        } else {
            []
        }
    }
}
