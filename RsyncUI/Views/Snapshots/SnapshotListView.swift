//
//  SnapshotListView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import SwiftUI

struct SnapshotListView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @EnvironmentObject var snapshotdata: SnapshotData

    @Binding var snapshotrecords: Logrecordsschedules?
    @Binding var selecteduuids: Set<UUID>

    var body: some View {
        Table(logrecords, selection: $selecteduuids) {
            TableColumn("snapshotCatalog") { data in
                if let snapshotCatalog = data.snapshotCatalog {
                    Text(snapshotCatalog)
                }
            }
            .width(max: 40)

            TableColumn("dateExecuted") { data in
                Text(data.dateExecuted)
            }
            .width(max: 150)
            TableColumn("period") { data in
                if let period = data.period {
                    Text(period)
                }
            }
            .width(max: 200)
            TableColumn("days") { data in
                if let days = data.days {
                    Text(days)
                }
            }
            .width(max: 60)
            TableColumn("resultExecuted") { data in
                Text(data.resultExecuted)
            }
            .width(max: 250)
        }
    }

    var logrecords: [Logrecordsschedules] {
        return snapshotdata.getsnapshotdata() ?? []
    }
}
