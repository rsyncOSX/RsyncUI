//
//  SchedulesTab.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 07/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//
// SCHEDULES IS NOT SUPPORTED FOR THE MOMENT

import SwiftUI

struct SidebarSchedulesView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    @StateObject private var logrecords = RsyncUIlogrecords()

    var body: some View {
        VStack(alignment: .leading) {
            headingtitle

            ScheduleView(selectedprofile: $selectedprofile,
                         reload: $reload)
                .environmentObject(logrecords)
        }
        .padding()
        .task {
            /*
            if selectedprofile == nil {
                selectedprofile = SharedReference.shared.defaultprofile
            }
             */
            // Initialize the Stateobject
            await logrecords.update(profile: selectedprofile, validhiddenIDs: rsyncUIdata.validhiddenIDs)
        }
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
