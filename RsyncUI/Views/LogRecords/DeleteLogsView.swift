//
//  DeleteLogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/03/2021.
//

import SwiftUI

struct DeleteLogsView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var selectedloguuids: Set<UUID>
    @Binding var logrecords: [LogRecords]?
    @Binding var logs: [Log]

    var selectedprofile: String?

    var body: some View {
        VStack {
            Text("Delete ^[\(selectedloguuids.count) log](inflect: true)")
                .font(.title2)

            Spacer()

            HStack {
                Button("Delete") { deletelogs(selectedloguuids) }
                    .buttonStyle(ColorfulRedButtonStyle())

                Button("Cancel") { dismiss() }
                    .buttonStyle(ColorfulButtonStyle())
            }
            .padding()
        }
        .padding()
    }

    func deletelogs(_ uuids: Set<UUID>) {
        if var records = logrecords {
            var indexset = IndexSet()

            for i in 0 ..< records.count {
                for j in 0 ..< uuids.count {
                    if let index = records[i].logrecords?.firstIndex(
                        where: { $0.id == uuids[uuids.index(uuids.startIndex, offsetBy: j)] })
                    {
                        indexset.insert(index)
                    }
                }
                records[i].logrecords?.remove(atOffsets: indexset)
                indexset.removeAll()
            }
            WriteLogRecordsJSON(selectedprofile, records)
            selectedloguuids.removeAll()
            Task {
                let actorreadlogs = ActorReadLogRecordsJSON()
                logs = await actorreadlogs.updatelogsbyhiddenID(records, -1) ?? []
            }
            dismiss()
        }
    }
}
