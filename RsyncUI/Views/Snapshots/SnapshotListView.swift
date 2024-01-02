//
//  SnapshotListView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import SwiftUI

struct SnapshotListView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @Binding var snapshotdata: SnapshotData
    @Binding var snapshotrecords: LogrecordSnapshot?
    @Binding var filterstring: String

    @Binding var selectedconfig: Configuration?
    @State private var confirmdelete: Bool = false

    var body: some View {
        if logrecords.count == 0,
           selectedconfig != nil,
           selectedconfig?.task == SharedReference.shared.snapshot,
           snapshotdata.snapshotlist == false
        {
            ContentUnavailableView {
                Label("There are no snapshot records by this search string in Date or Tag", 
                      systemImage: "doc.richtext.fill")
            } description: {
                Text("Change search string to filter records")
            }
        } else {
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
                NSLocalizedString("Delete snapshots(s)", comment: "")
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
        }
    }

    var logrecords: [LogrecordSnapshot] {
        if filterstring.isEmpty {
            return snapshotdata.getsnapshotdata() ?? []
        } else {
            return snapshotdata.getsnapshotdata()?.filter { ($0.dateExecuted).contains(filterstring) ||
                ($0.period ?? "").contains(filterstring)
            } ?? []
        }
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
