//
//  SnapshotListView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import SwiftUI

struct SnapshotListView: View {
    @Binding var snapshotdata: ObservableSnapshotData
    @Binding var filterstring: String

    @Binding var selectedconfig: SynchronizeConfiguration?
    @State private var pendingDeletion: (ids: Set<LogRecordSnapshot.ID>, configuration: SynchronizeConfiguration)?
    @FocusState private var snapshotTableIsFocused: Bool

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
            TableColumn("Tag") { data in
                if let period = data.period {
                    if period.contains("Delete") {
                        Text(period)
                            .foregroundStyle(.red)
                    } else {
                        Text(period)
                    }
                }
            }
            .width(max: 200)
            TableColumn("Last") { data in
                if let days = data.latest {
                    Text(days)
                }
            }
            .width(max: 60)
            TableColumn("Result") { data in
                Text(data.resultExecuted)
            }
            .width(max: 250)
        }
        .focused($snapshotTableIsFocused)
        .defaultFocus($snapshotTableIsFocused, true)
        .onChange(of: snapshotdata.snapshotuuidsfordelete) {
            if snapshotdata.snapshotuuidsfordelete.isEmpty == false {
                snapshotTableIsFocused = true
            }
        }
        .confirmationDialog(pendingDeletion?.ids.count == 1 ? "Delete 1 snapshot" :
            "Delete \(pendingDeletion?.ids.count ?? 0) snapshots",
            item: $pendingDeletion) { request in
                Button("Delete", role: .destructive) {
                    delete(request)
                }
        }
        .onDeleteCommand {
            guard snapshotdata.snapshotuuidsfordelete.isEmpty == false, let selectedconfig else { return }
            pendingDeletion = (snapshotdata.snapshotuuidsfordelete, selectedconfig)
        }
        .overlay {
            if logrecords.count == 0,
               selectedconfig != nil,
               selectedconfig?.task == SharedReference.shared.snapshot,
               snapshotdata.snapshotlist == false {
                ContentUnavailableView {
                    Label("No snapshots match this search",
                          systemImage: "doc.richtext.fill")
                } description: {
                    Text("Try searching by date or tag.")
                }
            }
        }
    }

    var logrecords: [LogRecordSnapshot] {
        if filterstring.isEmpty {
            snapshotdata.getsnapshotdata() ?? []
        } else {
            snapshotdata.getsnapshotdata()?.filter { ($0.dateExecuted).contains(filterstring) ||
                ($0.period ?? "").contains(filterstring)
            } ?? []
        }
    }

    private func delete(_ request: (ids: Set<LogRecordSnapshot.ID>, configuration: SynchronizeConfiguration)) {
        snapshotdata.snapshotuuidsfordelete = request.ids
        snapshotdata.delete = DeleteSnapshots(config: request.configuration,
                                              snapshotdata: snapshotdata,
                                              logrecordssnapshot: snapshotdata.getsnapshotdata())
        snapshotdata.inprogressofdelete = true
        snapshotdata.delete?.deletesnapshots()
    }
}
