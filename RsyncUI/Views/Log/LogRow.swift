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
                Text(Image(systemName: "arrowtriangle.right"))
                    .frame(width: 20, alignment: .leading)
            } else {
                Text("")
                    .frame(width: 20, alignment: .leading)
            }
            Text(localizeddate)
                .modifier(FixedTag(250, .leading))
            Text(logrecord.resultExecuted ?? "")
                .modifier(FixedTag(300, .leading))

            Spacer()
        }
    }

    var localizeddate: String {
        if let dateexecuted = logrecord.dateExecuted {
            guard dateexecuted.isEmpty == false else { return "" }
            let usdate = dateexecuted.en_us_date_from_string()
            return usdate.long_localized_string_from_date()
        }
        return ""
    }
}
