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
    /// Alert button
    @State private var showingAlert = false
    /// Focusfield
    @FocusState private var focusField: ReplaceConfigurationField?

    var body: some View {
        HStack {
            // Column 1
            GlobalChangeFormView(newdata: $newdata,
                                 showingAlert: $showingAlert,
                                 configurations: configurations,
                                 focusField: $focusField)

            // Column 2
            VStack(alignment: .leading) {
                ConfigurationsTableGlobalChanges(newdata: $newdata)
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Update all configurations?"),
                primaryButton: .default(Text("Update")) {
                    newdata.updateglobalchangedconfigurations()
                    // any snapshotstasks
                    if let snapshotstask = newdata.notchangedsnapshotconfigurations,
                       let globalupdate = newdata.globalchangedconfigurations {
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
                handleSubmit()
            case .remotecatalogField:
                handleSubmit()
            case .remoteuserField:
                handleSubmit()
            case .remoteserverField:
                handleSubmit()
            case .synchronizeIDField:
                handleSubmit()
            default:
                return
            }
        }
    }

    var configurations: [SynchronizeConfiguration] {
        if let configurations = newdata.globalchangedconfigurations {
            configurations
        } else {
            []
        }
    }

    private func handleSubmit() {
        newdata.updateglobalchangedconfigurations()
        showingAlert = true
    }
}
