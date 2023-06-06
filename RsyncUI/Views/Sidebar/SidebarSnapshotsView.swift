//
//  SidebarSnapshots.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import SwiftUI

struct SidebarSnapshotsView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations

    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    @State private var selectedconfig: Configuration?

    var body: some View {
        SnapshotsView(selectedconfig: $selectedconfig, reload: $reload)
            .padding()
    }
}
