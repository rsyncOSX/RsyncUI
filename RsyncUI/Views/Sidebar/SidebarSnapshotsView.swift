//
//  SidebarSnapshots.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import SwiftUI

struct SidebarSnapshotsView: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata

    @State private var selectedconfig: Configuration?
    @Binding var reload: Bool

    @State private var logs: Bool = false

    var body: some View {
        VStack {
            headingtitle

            if logs == false {
                SnapshotsView(selectedconfig: $selectedconfig.onChange { rsyncUIData.update() },
                              reload: $reload,
                              logs: $logs)
            } else {
                SnapshotLogsView(reload: $reload,
                                 selectedconfig: $selectedconfig,
                                 logs: $logs)
            }
        }
        .padding()
    }

    var headingtitle: some View {
        HStack {
            VStack {
                Text(NSLocalizedString("Snapshots", comment: "SidebarSnapshotsView"))
                    .modifier(Tagheading(.title2, .leading))
                    .foregroundColor(Color.blue)
            }

            Spacer()
        }
        .padding()
    }
}
