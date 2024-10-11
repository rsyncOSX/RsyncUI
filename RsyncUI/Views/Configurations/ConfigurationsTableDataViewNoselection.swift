//
//  ConfigurationsTableDataViewNoselection.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/10/2024.
//

import SwiftUI

struct ConfigurationsTableDataViewNoselection: View {

    let profile: String?
    let configurations: [SynchronizeConfiguration]

    var body: some View {
        Table(configurations) {
            TableColumn("Profile") { _ in
                Text(profile ?? "Default profile")
            }
            .width(min: 50, max: 200)
            TableColumn("Synchronize ID") { data in
                if data.backupID.isEmpty == true {
                    Text("Synchronize ID")

                } else {
                    Text(data.backupID)
                }
            }
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
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
            }
            .width(max: 50)
            TableColumn("Last") { data in
                Text(data.dateRun ?? "")
            }
            .width(max: 120)
        }
    }
}

