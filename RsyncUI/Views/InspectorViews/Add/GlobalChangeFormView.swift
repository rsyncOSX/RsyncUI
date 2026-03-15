import SwiftUI

struct GlobalChangeFormView: View {
    @Binding var newdata: ObservableGlobalchangeConfigurations
    @Binding var showingAlert: Bool
    let configurations: [SynchronizeConfiguration]
    let focusField: FocusState<ReplaceConfigurationField?>.Binding

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                ConditionalGlassButton(
                    systemImage: "arrow.down",
                    text: "Update",
                    helpText: "Update task"
                ) {
                    guard newdata.whatischanged.isEmpty == false else { return }
                    showingAlert = true
                }
                .disabled(configurations.isEmpty)
            }

            VStack(alignment: .leading) { synchronizeID }
            VStack(alignment: .leading) { localandremotecatalog }
            VStack(alignment: .leading) { remoteuserandserver }

            Spacer()

            Text("ALL or SELECTED to be updated")
                .padding(.bottom, 10)
        }
        .padding()
    }

    private func updateChangeSet(_ key: GlobalchangeConfiguration, value: String) {
        Task {
            try? await Task.sleep(seconds: 2)
            if value.isEmpty {
                if newdata.whatischanged.contains(key) {
                    newdata.whatischanged.remove(key)
                }
            } else {
                if newdata.whatischanged.contains(key) == false {
                    newdata.whatischanged.insert(key)
                }
            }
        }
    }

    private var synchronizeID: some View {
        Section(header: headerID) {
            HStack {
                EditValueScheme(140, "Synchronize ID", $newdata.occurence_backupID)
                    .onChange(of: newdata.occurence_backupID) {
                        updateChangeSet(.backupID, value: newdata.occurence_backupID)
                    }
                    .disabled(configurations.isEmpty)
                    .focused(focusField, equals: .synchronizeIDField)

                EditValueScheme(140, "Replace", $newdata.replace_backupID)
                    .onChange(of: newdata.replace_backupID) {
                        updateChangeSet(.backupID, value: newdata.replace_backupID)
                    }
                    .disabled(configurations.isEmpty)
                    .focused(focusField, equals: .synchronizeIDField)
            }
        }
    }

    private var localandremotecatalog: some View {
        Section(header: headerlocalremote) {
            HStack {
                EditValueScheme(140, "Source folder", $newdata.occurence_localcatalog)
                    .onChange(of: newdata.occurence_localcatalog) {
                        updateChangeSet(.localcatalog, value: newdata.occurence_localcatalog)
                    }
                    .disabled(configurations.isEmpty)
                    .focused(focusField, equals: .localcatalogField)

                EditValueScheme(140, "Replace", $newdata.replace_localcatalog)
                    .onChange(of: newdata.replace_localcatalog) {
                        updateChangeSet(.localcatalog, value: newdata.replace_localcatalog)
                    }
                    .disabled(configurations.isEmpty)
                    .focused(focusField, equals: .localcatalogField)
            }

            HStack {
                EditValueScheme(140, "Destination folder", $newdata.occurence_remotecatalog)
                    .onChange(of: newdata.occurence_remotecatalog) {
                        updateChangeSet(.remotecatalog, value: newdata.occurence_remotecatalog)
                    }
                    .disabled(configurations.isEmpty)
                    .focused(focusField, equals: .remotecatalogField)

                EditValueScheme(140, "Replace", $newdata.replace_remotecatalog)
                    .onChange(of: newdata.replace_remotecatalog) {
                        updateChangeSet(.remotecatalog, value: newdata.replace_remotecatalog)
                    }
                    .disabled(configurations.isEmpty)
                    .focused(focusField, equals: .remotecatalogField)
            }
        }
    }

    private var remoteuserandserver: some View {
        Section(header: headerremote) {
            EditValueScheme(300, "Remote user", $newdata.occurence_remoteuser)
                .onChange(of: newdata.occurence_remoteuser) {
                    updateChangeSet(.remoteuser, value: newdata.occurence_remoteuser)
                }
                .disabled(configurations.isEmpty)
                .focused(focusField, equals: .remoteuserField)

            EditValueScheme(300, "Remote server", $newdata.occurence_remoteserver)
                .onChange(of: newdata.occurence_remoteserver) {
                    updateChangeSet(.remoteserver, value: newdata.occurence_remoteserver)
                }
                .disabled(configurations.isEmpty)
                .focused(focusField, equals: .remoteserverField)
        }
    }

    private var headerlocalremote: some View {
        Text("Folder parameters")
            .modifier(FixedTag(300, .leading))
            .font(.title3)
            .fontWeight(.bold)
    }

    private var headerremote: some View {
        Text("Remote parameters")
            .modifier(FixedTag(300, .leading))
            .font(.title3)
            .fontWeight(.bold)
    }

    private var headerID: some View {
        Text("Synchronize ID")
            .modifier(FixedTag(300, .leading))
            .font(.title3)
            .fontWeight(.bold)
    }
}
