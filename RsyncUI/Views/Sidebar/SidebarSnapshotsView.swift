//
//  SidebarSnapshotsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import SwiftUI

struct SidebarSnapshotsView: View {
    @Binding var reload: Bool

    var body: some View {
        SnapshotsView(reload: $reload)
            .padding()
    }
}
