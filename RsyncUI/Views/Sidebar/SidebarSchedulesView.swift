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
        VStack(alignment: .leading) {
            headingtitle

            ScheduleView(selectedprofile: $selectedprofile,
                         reload: $reload)
        }
        .padding()
        .onAppear(perform: {
            if selectedprofile == nil {
                selectedprofile = "Default profile"
            }
        })
    }

    var headingtitle: some View {
        HStack {
            VStack {
                Text("Schedules")
                    .modifier(Tagheading(.title2, .leading))
                    .foregroundColor(Color.blue)
            }

            Spacer()
        }
        .padding()
        .frame(width: 200)
    }
}
