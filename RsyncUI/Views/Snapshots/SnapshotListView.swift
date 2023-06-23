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

    var body: some View {
        Table(logrecords, selection: $snapshotdata.snapshotuuidsfordelete) {
            TableColumn("Snap") { data in
                if let snapshotCatalog = data.snapshotCatalog {
                    Text(snapshotCatalog)
                }
            }
            .width(max: 40)

            TableColumn("Date") { data in
                Text(data.dateExecuted)
            }
            .width(max: 150)
            TableColumn("Period") { data in
                if let period = data.period {
                    if period.contains("Delete") {
                        Text(period)
                            .foregroundColor(.red)
                    } else {
                        Text(period)
                    }
                }
            }
            .width(max: 200)
            TableColumn("Days") { data in
                if let days = data.days {
                    Text(days)
                }
            }
            .width(max: 60)
            TableColumn("Result") { data in
                Text(data.resultExecuted)
            }
            .width(max: 250)
        }
    }

    var logrecords: [Logrecordsschedules] {
        return snapshotdata.getsnapshotdata() ?? []
    }
}
