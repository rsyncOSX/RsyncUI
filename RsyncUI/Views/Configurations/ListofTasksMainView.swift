//
//  ListofTasksMainView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import SwiftUI

struct ListofTasksMainView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata

    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var filterstring: String
    @Binding var reload: Bool
    @Binding var doubleclick: Bool
    // Progress of synchronization
    @Binding var progress: Double

    @State private var confirmdelete: Bool = false

    let executeprogressdetails: ExecuteProgressDetails
    let max: Double

    var body: some View {
        tabledata
            .overlay {
                if (rsyncUIdata.configurations ?? []).filter(
                    { filterstring.isEmpty ? true : $0.backupID.contains(filterstring) }).isEmpty
                {
                    ContentUnavailableView {
                        Label("There are no tasks by this Synchronize ID", systemImage: "doc.richtext.fill")
                    } description: {
                        Text("Try to search for another ID or \n If new user, add Tasks.")
                    }
                }
            }
            .searchable(text: $filterstring)
    }

    var tabledata: some View {
        Table((rsyncUIdata.configurations ?? []).filter {
            filterstring.isEmpty ? true : $0.backupID.contains(filterstring)
        }, selection: $selecteduuids) {
            TableColumn("%") { data in
                if data.hiddenID == executeprogressdetails.hiddenIDatwork, max > 0 {
                    ProgressView("",
                                 value: progress,
                                 total: max)
                        .frame(alignment: .center)
                }
            }
            .width(min: 50, ideal: 50)
            TableColumn("Profile") { data in
                if markconfig(data) {
                    Text(data.profile ?? "Default profile")
                        .foregroundColor(.red)
                } else {
                    Text(data.profile ?? "Default profile")
                }
            }
            .width(min: 50, max: 200)
            TableColumn("Synchronize ID", value: \.backupID)
                .width(min: 50, max: 200)
            TableColumn("Task", value: \.task)
                .width(max: 80)
            TableColumn("Local catalog", value: \.localCatalog)
                .width(min: 80, max: 300)
            TableColumn("Remote catalog", value: \.offsiteCatalog)
                .width(min: 80, max: 300)
            TableColumn("Server") { data in
                if data.offsiteServer.count > 0 {
                    Text(data.offsiteServer)
                } else {
                    Text("localhost")
                }
            }
            .width(min: 50, max: 80)
            TableColumn("Days") { data in
                if markconfig(data) {
                    Text(data.dayssincelastbackup ?? "")
                        .foregroundColor(.red)
                } else {
                    Text(data.dayssincelastbackup ?? "")
                }
            }
            .width(max: 50)
            TableColumn("Last") { data in
                if markconfig(data) {
                    Text(data.dateRun ?? "")
                        .foregroundColor(.red)
                } else {
                    if data.dateRun?.isEmpty == false {
                        Text(data.dateRun ?? "")
                    } else {
                        if executeprogressdetails.taskisestimatedbyUUID(data.id) {
                            Text("Verified")
                                .foregroundColor(.green)
                        } else {
                            Text("Not verified")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .width(max: 120)
        }
        .confirmationDialog(
            NSLocalizedString("Delete configuration(s)", comment: "")
                + "?",
            isPresented: $confirmdelete
        ) {
            Button("Delete") {
                delete()
                confirmdelete = false
            }
        }
        .contextMenu(forSelectionType: Configuration.ID.self) { _ in
            // ...
        } primaryAction: { _ in
            doubleclick = true
        }
        .onDeleteCommand {
            confirmdelete = true
        }
    }

    func delete() {
        let deleteconfigurations =
            UpdateConfigurations(profile: rsyncUIdata.profile,
                                 configurations: rsyncUIdata.getallconfigurations())
        deleteconfigurations.deleteconfigurations(uuids: selecteduuids)
        selecteduuids.removeAll()
        reload = true
    }

    func markconfig(_ config: Configuration?) -> Bool {
        if config?.dateRun != nil {
            if let secondssince = config?.lastruninseconds {
                if secondssince / (60 * 60 * 24) > Double(SharedReference.shared.marknumberofdayssince) {
                    return true
                }
            }
        }
        return false
    }
}
