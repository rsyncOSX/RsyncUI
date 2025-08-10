//
//  GlobalChangeTaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/11/2024.
//

import SwiftUI

enum ReplaceConfigurationField: Hashable {
    case synchronizeIDField
    case localcatalogField
    case remotecatalogField
    case remoteuserField
    case remoteserverField
}

struct GlobalChangeTaskView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations

    @State private var newdata = ObservableGlobalchangeConfigurations()
    // Alert button
    @State private var showingAlert = false
    // Focusfield
    @FocusState private var focusField: ReplaceConfigurationField?

    var body: some View {
        HStack {
            // Column 1

            VStack(alignment: .leading) {
                HStack {
                    Button("Update") {
                        guard newdata.whatischanged.isEmpty == false else { return }
                        newdata.updateglobalchangedconfigurations()
                        showingAlert = true
                    }
                    .help("Update task")
                    .disabled(configurations.isEmpty)
                    .buttonStyle(ColorfulButtonStyle())
                }

                VStack(alignment: .leading) { synchronizeID }

                VStack(alignment: .leading) { localandremotecatalog }

                VStack(alignment: .leading) { remoteuserandserver }

                Spacer()

                Text("ALL or SELECTED to be updated")
                    .padding(.bottom, 10)
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

    var synchronizeID: some View {
        Section(header: headerID) {
            HStack {
                // Synchronize ID
                EditValueScheme(140, NSLocalizedString("Synchronize ID", comment: ""), $newdata.occurence_backupID)
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

                EditValueScheme(140, NSLocalizedString("Replace", comment: ""), $newdata.replace_backupID)
                    .onChange(of: newdata.replace_backupID) {
                        Task {
                            try await Task.sleep(seconds: 2)
                            if newdata.replace_backupID.isEmpty {
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
    }

    var localandremotecatalog: some View {
        Section(header: headerlocalremote) {
            HStack {
                // localcatalog
                EditValueScheme(140, NSLocalizedString("Source folder", comment: ""), $newdata.occurence_localcatalog)
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

                // localcatalog
                EditValueScheme(140, NSLocalizedString("Replace", comment: ""), $newdata.replace_localcatalog)
                    .onChange(of: newdata.replace_localcatalog) {
                        Task {
                            try await Task.sleep(seconds: 2)
                            if newdata.replace_localcatalog.isEmpty {
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
            }

            HStack {
                EditValueScheme(140, NSLocalizedString("Destination folder", comment: ""), $newdata.occurence_remotecatalog)
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

                EditValueScheme(140, NSLocalizedString("Replace", comment: ""), $newdata.replace_remotecatalog)
                    .onChange(of: newdata.replace_remotecatalog) {
                        Task {
                            try await Task.sleep(seconds: 2)
                            if newdata.replace_remotecatalog.isEmpty {
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
    }

    var remoteuserandserver: some View {
        Section(header: headerremote) {
            // Remote user
            EditValueScheme(300, NSLocalizedString("Remote user", comment: ""), $newdata.occurence_remoteuser)
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
            EditValueScheme(300, NSLocalizedString("Remote server", comment: ""), $newdata.occurence_remoteserver)
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

    // Headers (in sections)
    var headerlocalremote: some View {
        Text("Folder parameters")
            .modifier(FixedTag(300, .leading))
            .font(.title3)
            //.foregroundColor(.blue)
            .fontWeight(.bold)
    }

    var headerremote: some View {
        Text("Remote parameters - replace string")
            .modifier(FixedTag(300, .leading))
            .font(.title3)
            // .foregroundColor(.blue)
            .fontWeight(.bold)
    }

    var headerID: some View {
        Text("Synchronize ID")
            .modifier(FixedTag(300, .leading))
            .font(.title3)
            // .foregroundColor(.blue)
            .fontWeight(.bold)
    }

    var configurations: [SynchronizeConfiguration] {
        if let configurations = newdata.globalchangedconfigurations {
            configurations
        } else {
            []
        }
    }
}
