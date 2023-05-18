//
//  TableListofTasksProgress.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 18/05/2023.
//

import SwiftUI

struct TableListofTasksProgress: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @EnvironmentObject var executedetails: InprogressCountExecuteOneTaskDetails

    // @Binding var selectedconfig: Configuration?
    // Used when selectable and starting progressview
    @Binding var selecteduuids: Set<UUID>
    @Binding var inwork: Int
    @Binding var filterstring: String
    @Binding var reload: Bool
    @Binding var confirmdelete: Bool

    var body: some View {
        VStack {
            tabledata
        }
        .searchable(text: $filterstring)
    }

    var tabledata: some View {
        Table(configurationssorted, selection: $selecteduuids) {
            TableColumn("Progress") { data in
                ZStack {
                    if data.hiddenID == inwork && executedetails.isestimating() == false {
                        ProgressView("",
                                     value: executedetails.getcurrentprogress(),
                                     total: maxcount)
                            .onChange(of: executedetails.getcurrentprogress(), perform: { _ in })
                            .frame(width: 40, alignment: .center)
                    } else {
                        Text("")
                            .modifier(FixedTag(20, .leading))
                    }
                    if selecteduuids.contains(data.id) && data.hiddenID != inwork {
                        Text(Image(systemName: "arrowtriangle.right"))
                            .modifier(FixedTag(20, .leading))
                    } else {
                        Text("")
                            .modifier(FixedTag(20, .leading))
                    }
                }
            }

            TableColumn("Profile") { data in
                if markconfig(data) {
                    Text(data.profile ?? "Default profile")
                        .foregroundColor(.red)
                } else {
                    Text(data.profile ?? "Default profile")
                }
            }
            .width(min: 100, max: 200)
            TableColumn("Synchronize ID", value: \.backupID)
                .width(min: 100, max: 200)
            TableColumn("Last") { data in
                if markconfig(data) {
                    Text(data.dateRun ?? "")
                        .foregroundColor(.red)
                } else {
                    Text(data.dateRun ?? "")
                }
            }
            .width(max: 120)
            TableColumn("Task", value: \.task)
                .width(max: 80)
            TableColumn("Local catalog", value: \.localCatalog)
                .width(min: 100, max: 300)
            TableColumn("Remote catalog", value: \.offsiteCatalog)
                .width(min: 100, max: 300)
            TableColumn("Server", value: \.offsiteServer)
                .width(max: 70)
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
