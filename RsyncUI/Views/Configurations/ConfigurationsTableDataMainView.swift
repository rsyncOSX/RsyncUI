//
//  ConfigurationsTableDataMainView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/04/2024.
//

import SwiftUI

struct ConfigurationsTableDataMainView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var filterstring: String
    @Binding var progress: Double

    let executeprogressdetails: ExecuteProgressDetails
    let max: Double

    var body: some View {
        Table(configurations.filter {
            filterstring.isEmpty ? true : $0.backupID.contains(filterstring)
        }, selection: $selecteduuids) {
            TableColumn("%") { data in
                if data.hiddenID == executeprogressdetails.hiddenIDatwork, max > 0, progress <= max {
                    ProgressView("",
                                 value: progress,
                                 total: max)
                        .frame(alignment: .center)
                }
            }
            .width(min: 70, ideal: 70)
            .defaultVisibility(visible_progress)
            TableColumn("Profile") { _ in
                Text(rsyncUIdata.profile ?? SharedReference.shared.defaultprofile)
            }
            .width(min: 50, max: 100)
            .defaultVisibility(visible_not_progress)
            TableColumn("Synchronize ID") { data in
                if let index = executeprogressdetails.estimatedlist?.firstIndex(where: { $0.id == data.id }) {
                    let color: Color = executeprogressdetails.estimatedlist?[index].datatosynchronize == true ? .blue : .red

                    if data.backupID.isEmpty == true {
                        Text("Synchronize ID")
                            .foregroundColor(color)
                    } else {
                        Text(data.backupID)
                            .foregroundColor(color)
                    }
                } else {
                    if data.backupID.isEmpty == true {
                        Text("Synchronize ID")
                            .contextMenu {
                                Button("Temporarly halt task") {}
                            }

                    } else {
                        Text(data.backupID)
                            .contextMenu {
                                Button("Temporarly halt task") {
                                    let index = getindex(selecteduuids)
                                    guard index != -1 else { return }
                                    updatehalted(index)
                                }
                            }
                    }
                }
            }
            TableColumn("Task", value: \.task)
                .width(max: 80)
            TableColumn("Local catalog", value: \.localCatalog)
                .width(min: 120, max: 400)
            TableColumn("Remote catalog", value: \.offsiteCatalog)
                .width(min: 120, max: 400)
            TableColumn("Server") { data in
                if data.offsiteServer.count > 0 {
                    Text(data.offsiteServer)
                } else {
                    Text("localhost")
                }
            }
            .width(min: 50, max: 90)
            TableColumn("Days") { data in
                var seconds: Double {
                    if let date = data.dateRun {
                        let lastbackup = date.en_us_date_from_string()
                        return lastbackup.timeIntervalSinceNow * -1
                    } else {
                        return 0
                    }
                }
                let color: Color = markconfig(seconds) == true ? .red : .white

                Text(String(format: "%.2f", seconds / (60 * 60 * 24)))
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                    .foregroundColor(color)
            }
            .width(max: 50)
            TableColumn("Last") { data in
                Text(data.dateRun ?? "")
            }
            .width(max: 120)
        }
    }
    
    var configurations: [SynchronizeConfiguration] {
        return rsyncUIdata.configurations ?? []
    }

    var visible_progress: Visibility {
        if max == 0 {
            .hidden
        } else {
            .visible
        }
    }

    var visible_not_progress: Visibility {
        if max == 0 {
            .visible
        } else {
            .hidden
        }
    }

    private func markconfig(_ seconds: Double) -> Bool {
        seconds / (60 * 60 * 24) > Double(SharedReference.shared.marknumberofdayssince)
    }
    
    private func halted(_ task: String) -> Halted {
        switch task {
            case "synchronize":
            return .synchronize
        case "syncremote":
            return .syncremote
        case "snapshot":
            return .snapshot
        default:
            return .synchronize
        }
    }
    
    private func getindex(_ uuids: Set<UUID>) -> Int {
        if let configurations = rsyncUIdata.configurations  {
            if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                return index
            } else {
                return -1
            }
        } else {
            return -1
        }
    }
    
    private func updatehalted(_ index: Int) {
        // Decide if already halted and enable task again, or
        // halt a new task
        print(rsyncUIdata.configurations?[index])
        
        /*
        let task = rsyncUIdata.configurations?[index].task
        rsyncUIdata.configurations?[index].halted = halted(task)
        rsyncUIdata.configurations?[index].task = SharedReference.shared.halted
         */
        
    }
}


enum Halted: Int {
    case synchronize = 1 // before halted synchronize
    case syncremote = 2 // as above but syncremote
    case snapshot = 3 // as above but
}
