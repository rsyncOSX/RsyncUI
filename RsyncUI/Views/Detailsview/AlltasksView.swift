//
//  AlltasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/11/2023.
//

import Foundation
import SwiftUI

struct AlltasksView: View {
    var body: some View {
        VStack {
            Table(data) {
                TableColumn("Profile") { data in
                    Text(data.profile ?? "")
                }
                .width(min: 100, max: 200)
                TableColumn("Synchronize ID", value: \.backupID)
                    .width(min: 100, max: 200)
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
                    Text(data.dateRun ?? "")
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
        }
        .padding()
    }

    var data: [SynchronizeConfiguration] {
        Allprofilesandtasks().alltasks?.sorted(by: { conf1, conf2 in
            if let date1 = conf1.dateRun, let date2 = conf2.dateRun {
                if date1.en_us_date_from_string() > date2.en_us_date_from_string() {
                    return true
                } else {
                    return false
                }
            }
            return false
        }) ?? []
    }

    func markconfig(_ seconds: Double) -> Bool {
        seconds / (60 * 60 * 24) > Double(SharedReference.shared.marknumberofdayssince)
    }
}
