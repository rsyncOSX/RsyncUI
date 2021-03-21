//
//  SchedulesTab.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 07/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct SidebarSchedulesView: View {
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    var body: some View {
        VStack {
            headingtitle

            SchedulesView(selectedprofile: $selectedprofile, reload: $reload)
        }
    }

    var headingtitle: some View {
        HStack {
            VStack {
                Text(NSLocalizedString("Schedules", comment: "SidebarLogsView"))
                    .modifier(Tagheading(.title2, .leading))
                    .foregroundColor(Color.blue)
            }

            Spacer()
        }
        .padding()
    }
}
