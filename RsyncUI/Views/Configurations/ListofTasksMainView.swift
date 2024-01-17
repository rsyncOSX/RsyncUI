//
//  ListofTasksMainView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import SwiftUI

struct ListofTasksMainView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var filterstring: String
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
            TableColumn("Profile") { _ in
                Text(rsyncUIdata.profile ?? "Default profile")
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
                var seconds: Double {
                    if let date = data.dateRun {
                        let lastbackup = date.en_us_date_from_string()
                        return lastbackup.timeIntervalSinceNow * -1
                    } else {
                        return 0
                    }
                }
                if markconfig(seconds) {
                    Text(String(format: "%.2f", seconds / (60 * 60 * 24)))
                        .foregroundColor(.red)
                } else {
                    Text(String(format: "%.2f", seconds / (60 * 60 * 24)))
                }
            }
            .width(max: 50)
            TableColumn("Last") { data in
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
        rsyncUIdata.configurations = deleteconfigurations.configurations
    }

    func markconfig(_ seconds: Double) -> Bool {
        return seconds / (60 * 60 * 24) > Double(SharedReference.shared.marknumberofdayssince)
    }
}
