//
//  ProfilesToUpdataView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/10/2024.
//

import SwiftUI

struct ProfilesToUpdataView: View {
    let configurations: [SynchronizeConfiguration]

    var body: some View {
        Table(configurations) {
            TableColumn("Synchronize ID : profilename") { data in
                if data.backupID.isEmpty == true {
                    Text("Synchronize ID")

                } else {
                    Text(data.backupID)
                }
            }
            .width(min: 150, max: 300)
            TableColumn("Task", value: \.task)
                .width(max: 80)
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
        .overlay {
            if configurations.count == 0 {
                ContentUnavailableView {
                    Label("All tasks has been synchronized in the past \(SharedReference.shared.marknumberofdayssince) days",
                          systemImage: "arrowshape.turn.up.left.fill")
                } description: {
                    Text("This is only due to Marknumberofdayssince set in the settings.")
                }
            }
        }
    }

    private func markconfig(_ seconds: Double) -> Bool {
        seconds / (60 * 60 * 24) > Double(SharedReference.shared.marknumberofdayssince)
    }
}
