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
    @State private var showdetails = false
    @State private var selectedconfig: Configuration?

    var body: some View {
        VStack {
            headingtitle

            if showdetails == false {
                SchedulesView(selectedprofile: $selectedprofile,
                              reload: $reload,
                              showdetails: $showdetails,
                              selectedconfig: $selectedconfig)

            } else {
                DetailsScheduleView(selectedprofile: $selectedprofile,
                                    reload: $reload,
                                    showdetails: $showdetails,
                                    selectedconfig: $selectedconfig)
            }
        }
        .padding()
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
