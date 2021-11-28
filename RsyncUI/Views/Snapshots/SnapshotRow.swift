//
//  SnapshotRow.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import SwiftUI

struct SnapshotRow: View {
    @Binding var selecteduuids: Set<UUID>
    var logrecord: Logrecordsschedules

    var body: some View {
        HStack {
            Spacer()

            if selecteduuids.contains(logrecord.id) {
                Text(Image(systemName: "arrowtriangle.right"))
                    .frame(width: 20, alignment: .leading)
            } else {
                Text("")
                    .frame(width: 20, alignment: .leading)
            }
            Text(logrecord.snapshotCatalog ?? "")
                .modifier(FixedTag(40, .leading))
            Text(logrecord.dateExecuted)
                .modifier(FixedTag(150, .leading))
            Text(logrecord.period ?? "")
                .modifier(FixedTag(200, .leading))
            Text(logrecord.days ?? "")
                .modifier(FixedTag(60, .leading))
            Text(logrecord.resultExecuted)
                .modifier(FixedTag(250, .leading))

            Spacer()
        }
    }
}
