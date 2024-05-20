//
//  ConfigurationsTableDataMainView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/04/2024.
//

import SwiftUI

@MainActor
struct ConfigurationsTableDataMainView: View {
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var filterstring: String
    @Binding var progress: Double

    let profile: String?
    let configurations: [SynchronizeConfiguration]
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
                Text(profile ?? "Default profile")
            }
            .width(min: 50, max: 100)
            .defaultVisibility(visible_not_progress)
            TableColumn("Synchronize ID", value: \.backupID)
                .width(min: 50, max: 150)
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
                Text(String(format: "%.2f", seconds / (60 * 60 * 24)))
            }
            .width(max: 50)
            TableColumn("Last") { data in
                Text(data.dateRun ?? "")
            }
            .width(max: 120)
        }
    }

    var visible_progress: Visibility {
        if max == 0 {
            return .hidden
        } else {
            return .visible
        }
    }

    var visible_not_progress: Visibility {
        if max == 0 {
            return .visible
        } else {
            return .hidden
        }
    }
}
