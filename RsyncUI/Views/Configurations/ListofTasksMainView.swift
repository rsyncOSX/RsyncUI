//
//  ListofTasksMainView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 18/05/2023.
//

import SwiftUI

struct ListofTasksMainView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @EnvironmentObject var executeprogressdetails: ExecuteProgressDetails

    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var filterstring: String
    @Binding var reload: Bool
    @Binding var doubleclick: Bool
    @State private var confirmdelete: Bool = false

    var showestimateicon: Bool

    var body: some View {
        tabledata
            .overlay {
                if configurationssorted.isEmpty {
                    ContentUnavailableView {
                        Label("There are no tasks by this Synchronize ID", systemImage: "doc.richtext.fill")
                    } description: {
                        Text("Try to search for another ID.")
                    }
                }
            }
            .searchable(text: $filterstring)
    }

    var tabledata: some View {
        Table(configurationssorted, selection: $selecteduuids) {
            TableColumn("%") { data in
                if data.hiddenID == executeprogressdetails.hiddenIDatwork {
                    ProgressView("",
                                 value: executeprogressdetails.currenttaskprogress,
                                 total: maxcount + 3)
                        .frame(alignment: .center)
                } else if executeprogressdetails.taskisestimatedbyUUID(data.id),
                          showestimateicon
                {
                    Image("green")
                        .resizable()
                        .frame(width: 15, height: 15, alignment: .trailing)
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

    var configurationssorted: [Configuration] {
        if filterstring.isEmpty {
            return rsyncUIdata.configurations ?? []
        } else {
            return rsyncUIdata.filterconfigurations(filterstring) ?? []
        }
    }

    var maxcount: Double {
        return executeprogressdetails.getmaxcountbytask()
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
