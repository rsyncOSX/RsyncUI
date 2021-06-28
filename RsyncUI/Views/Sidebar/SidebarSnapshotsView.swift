//
//  SidebarSnapshots.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import SwiftUI

struct SidebarSnapshotsView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata

    @State private var selectedconfig: Configuration?
    @Binding var reload: Bool

    var body: some View {
        VStack {
            headingtitle

            SnapshotsView(selectedconfig: $selectedconfig, reload: $reload)
        }
        .padding()
    }

    var headingtitle: some View {
        HStack {
            VStack {
                Text("Snapshots")
                    .modifier(Tagheading(.title2, .leading))
                    .foregroundColor(Color.blue)
            }

            Spacer()
        }
        .padding()
    }
}
