//
//  EstimateTableView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/11/2024.
//

import SwiftUI

struct EstimateTableView: View {
    @Environment(\.colorScheme) var colorScheme

    @Bindable var progressdetails: ProgressDetails
    let estimatinguuid: SynchronizeConfiguration.ID
    let configurations: [SynchronizeConfiguration]

    var body: some View {
        Table(configurations) {
            TableColumn("Synchronize ID") { data in
                HStack(spacing: 4) {
                    if data.id == estimatinguuid {
                        HStack {
                            Image(systemName: "arrowshape.right.fill")
                                .foregroundStyle(Color(.blue))

                            if data.backupID.isEmpty == true {
                                Text("No ID set")
                                    .foregroundStyle(color(uuid: data.id))
                            } else {
                                Text(data.backupID)
                                    .foregroundStyle(color(uuid: data.id))
                            }
                        }
                    } else {
                        if data.backupID.isEmpty == true {
                            Text("No ID set")
                                .foregroundStyle(color(uuid: data.id))
                        } else {
                            Text(data.backupID)
                                .foregroundStyle(color(uuid: data.id))
                        }
                    }

                    ConfigurationTaskBadge(task: data.task, hidesSynchronize: true)
                }
            }
            .width(min: 130, ideal: 160, max: 220)
            TableColumn("Source", value: \.localCatalog)
                .width(min: 80, max: 300)
            TableColumn("Destination", value: \.offsiteCatalog)
                .width(min: 80, max: 300)
            TableColumn("Server") { data in
                if data.offsiteServer.count > 0 {
                    Text(data.offsiteServer)
                } else {
                    Text("localhost")
                }
            }
            .width(min: 75, ideal: 85, max: 110)
        }
    }

    func color(uuid: UUID) -> Color {
        let filter = progressdetails.estimatedlist?.filter {
            $0.id == uuid
        }
        return filter?.isEmpty == false ? .blue : (colorScheme == .dark ? .white : .black)
    }
}
