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
    @Binding var snapshotrecords: LogrecordSnapshot?
    @Binding var selectedconfig: Configuration?
    @Binding var deleteiscompleted: Bool

    @State private var confirmdelete: Bool = false

    var body: some View {
        ZStack {
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
                TableColumn("Tag") { data in
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
            .confirmationDialog(
                NSLocalizedString("Delete configuration(s)", comment: "")
                    + "?",
                isPresented: $confirmdelete
            ) {
                Button("Delete") {
                    delete()
                    confirmdelete = false
                }
            }
            .onDeleteCommand {
                confirmdelete = true
            }

            if snapshotdata.inprogressofdelete == true { progressdelete }
        }
    }

    var logrecords: [LogrecordSnapshot] {
        return snapshotdata.getsnapshotdata() ?? []
    }

    var progressdelete: some View {
        ProgressView("",
                     value: Double(snapshotdata.remainingsnapshotstodelete),
                     total: Double(snapshotdata.maxnumbertodelete))
            .frame(width: 100, alignment: .center)
            .onDisappear(perform: {
                deleteiscompleted = true
            })
    }

    func delete() {
        if let config = selectedconfig {
            snapshotdata.delete = DeleteSnapshots(config: config,
                                                  snapshotdata: snapshotdata,
                                                  logrecordssnapshot: snapshotdata.getsnapshotdata())
            snapshotdata.inprogressofdelete = true
            snapshotdata.delete?.deletesnapshots()
        }
    }
}
