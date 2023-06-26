//
//  ListofTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 18/05/2023.
//

import SwiftUI

struct ListofTasksView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @EnvironmentObject var executedetails: InprogressCountExecuteOneTaskDetails

    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var inwork: Int
    @Binding var filterstring: String
    @Binding var reload: Bool
    @Binding var confirmdelete: Bool
    @Binding var reloadtasksviewlist: Bool
    @Binding var doubleclick: Bool

    var body: some View {
        VStack {
            if #available(macOS 13.0, *) {
                tabledata
            } else {
                tabledata_macos12
            }
        }
        .searchable(text: $filterstring)
    }

    var tabledata_macos12: some View {
        Table(configurationssorted, selection: $selecteduuids) {
            TableColumn("%") { data in
                if data.hiddenID == inwork && executedetails.isestimating() == false {
                    ProgressView("",
                                 value: executedetails.getcurrentprogress(),
                                 total: maxcount)
                        .onChange(of: executedetails.getcurrentprogress(), perform: { _ in })
                        .frame(alignment: .center)
                }
            }
            .width(max: 50)
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
                    Text(data.dateRun ?? "")
                }
            }
            .width(max: 120)
        }
        .confirmationDialog(
            NSLocalizedString("Delete configuration", comment: "")
                + "?",
            isPresented: $confirmdelete
        ) {
            Button("Delete") {
                delete()
                confirmdelete = false
            }
        }
    }

    @available(macOS 13.0, *)
    var tabledata: some View {
        Table(configurationssorted, selection: $selecteduuids) {
            TableColumn("%") { data in
                if data.hiddenID == inwork && executedetails.isestimating() == false {
                    ProgressView("",
                                 value: executedetails.getcurrentprogress(),
                                 total: maxcount)
                        .onChange(of: executedetails.getcurrentprogress(), perform: { _ in })
                        .frame(width: 35, alignment: .center)
                }
            }
            .width(max: 50)
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
                    Text(data.dateRun ?? "")
                }
            }
            .width(max: 120)
        }
        .confirmationDialog(
            NSLocalizedString("Delete configuration", comment: "")
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
    }

    var configurationssorted: [Configuration] {
        if filterstring.isEmpty {
            return rsyncUIdata.configurations ?? []
        } else {
            return rsyncUIdata.filterconfigurations(filterstring) ?? []
        }
    }

    var maxcount: Double {
        return executedetails.getmaxcountbytask(inwork)
    }

    func delete() {
        let deleteconfigurations =
            UpdateConfigurations(profile: rsyncUIdata.configurationsfromstore?.profile,
                                 configurations: rsyncUIdata.configurationsfromstore?.configurationData.getallconfigurations())
        deleteconfigurations.deleteconfigurations(uuids: selecteduuids)
        selecteduuids.removeAll()
        reload = true
        reloadtasksviewlist = true
    }

    func markconfig(_ config: Configuration?) -> Bool {
        if config?.dateRun != nil {
            if let secondssince = config?.lastruninseconds {
                if secondssince / (60 * 60 * 24) > SharedReference.shared.marknumberofdayssince {
                    return true
                }
            }
        }
        return false
    }
}
