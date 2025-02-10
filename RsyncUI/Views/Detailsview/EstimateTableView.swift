//
//  EstimateTableView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/11/2024.
//

import SwiftUI

struct EstimateTableView: View {
    @Bindable var estimateprogressdetails: EstimateProgressDetails
    let estimatinguuid: SynchronizeConfiguration.ID
    let configurations: [SynchronizeConfiguration]

    var body: some View {
        Table(configurations) {
            TableColumn("") { data in
                if data.id == estimatinguuid {
                    Image(systemName: "arrowshape.right.fill")
                        .foregroundColor(Color(.blue))
                }
            }
            .width(min: 25, max: 25)
            TableColumn("Synchronize ID") { data in
                if data.backupID.isEmpty == true {
                    Text("Synchronize ID")
                        .foregroundColor(color(uuid: data.id))

                } else {
                    Text(data.backupID)
                        .foregroundColor(color(uuid: data.id))
                }
            }
            .width(min: 50, max: 200)
            TableColumn("Task") { data in
                if data.task == SharedReference.shared.halted {
                    Image(systemName: "stop.fill")
                        .foregroundColor(Color(.red))
                } else {
                    Text(data.task)
                }
            }
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
        }
    }

    func color(uuid: UUID) -> Color {
        let filter = estimateprogressdetails.estimatedlist?.filter {
            $0.id == uuid
        }
        return filter?.isEmpty == false ? .blue : .white
    }
}
