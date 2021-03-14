//
//  ScheduleRowLogs.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 06/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct LogRow: View {
    @Binding var selecteduuids: Set<UUID>
    var logrecord: Log

    var body: some View {
        HStack {
            Spacer()

            if selecteduuids.contains(logrecord.id) {
                Text(Image(systemName: "arrowtriangle.right.fill"))
                    .foregroundColor(.green)
                    .frame(width: 20, alignment: .leading)
            } else {
                Text("")
                    .frame(width: 20, alignment: .leading)
            }
            Text(logrecord.dateExecuted ?? "")
                .modifier(FixedTag(150, .leading))
            Text(logrecord.resultExecuted ?? "")
                .modifier(FixedTag(200, .leading))

            Spacer()
        }
    }
}
