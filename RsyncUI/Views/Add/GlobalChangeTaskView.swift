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

    var body: some View {
        HStack {
            // Column 1
            VStack(alignment: .leading) {
                VStack(alignment: .leading) { synchronizeID }

                VStack(alignment: .leading) { localandremotecatalog }

                VStack(alignment: .leading) { remoteuserandserver }
            }
            .padding()

            // Column 2
            VStack(alignment: .leading) {
                Table(configurations) {
                    TableColumn("Synchronize ID") { data in
                        if data.backupID.isEmpty == true {
                            Text("Synchronize ID")

                        } else {
                            Text(data.backupID)
                        }
                    }
                    .width(min: 50, max: 150)
                    TableColumn("Local catalog", value: \.localCatalog)
                        .width(min: 180, max: 300)
                    TableColumn("Remote catalog", value: \.offsiteCatalog)
                        .width(min: 180, max: 300)
                    TableColumn("Remote user", value: \.offsiteUsername)
                        .width(min: 100, max: 150)
                    TableColumn("Server", value: \.offsiteServer)
                }
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Update all configurations?"),
                primaryButton: .default(Text("Update")) {
                    // any snapshotstasks
                    if let snapshotstask = newdata.notchangedsnapshotconfigurations,
                       let globalupdate = newdata.globalchangedconfigurations {
                        rsyncUIdata.configurations = globalupdate + snapshotstask
                    } else {
                        rsyncUIdata.configurations = newdata.globalchangedconfigurations
                    }
                    // Writeupdate to store
                },
                secondaryButton: .cancel {
                    newdata.globalchangedconfigurations = rsyncUIdata.configurations
                }
            )
        }
        .toolbar(content: {
            ToolbarItem {
                Button {
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
            }
        })
        .padding()
        .onAppear {
            // Synchronize and syncremote
            newdata.globalchangedconfigurations = rsyncUIdata.configurations?.compactMap { task in
                (task.task != SharedReference.shared.snapshot) ? task : nil
            }
            // Snapshottask
            newdata.notchangedsnapshotconfigurations = rsyncUIdata.configurations?.compactMap { task in
                (task.task == SharedReference.shared.snapshot) ? task : nil
            }
        }
        .onChange(of: newdata.whatischanged) {
            updated = !newdata.whatischanged.isEmpty
        }
    }

    var localandremotecatalog: some View {
        Section(header: headerlocalremote) {
            // localcatalog
            EditValue(300, NSLocalizedString("Global change local catalog", comment: ""), $newdata.occurence_localcatalog)
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
            EditValue(300, NSLocalizedString("Global change remote catalog", comment: ""), $newdata.occurence_remotecatalog)
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
        }
    }

    var remoteuserandserver: some View {
        Section(header: headerremote) {
            // Remote user
            EditValue(300, NSLocalizedString("Global change remote user", comment: ""), $newdata.occurence_remoteuser)
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
            // Remote server
            EditValue(300, NSLocalizedString("Global change remote server", comment: ""), $newdata.occurence_remoteserver)
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
        }
    }

    var synchronizeID: some View {
        Section(header: headerID) {
            // Synchronize ID
            EditValue(300, NSLocalizedString("Global change Synchronize ID", comment: ""), $newdata.occurence_backupID)
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
