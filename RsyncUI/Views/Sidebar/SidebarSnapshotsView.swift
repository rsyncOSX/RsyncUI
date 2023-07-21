//
//  SidebarSnapshots.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import SwiftUI

struct SidebarSnapshotsView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @Binding var reload: Bool

    @State private var selectedconfig: Configuration?

    var body: some View {
        SnapshotsView(reload: $reload)
            .padding()
    }
}
