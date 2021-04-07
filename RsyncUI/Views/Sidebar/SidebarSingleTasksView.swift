//
//  SidebarSingleTasksView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 12/02/2021.
//

import SwiftUI

struct SidebarSingleTasksView: View {
    @EnvironmentObject var rsyncOSXData: RsyncUIdata
    @Binding var reload: Bool

    var body: some View {
        VStack {
            headingtitle

            SingleTasksView(reload: $reload)
        }

        .padding()
    }

    var headingtitle: some View {
        HStack {
            ImageRsync()

            VStack(alignment: .leading) {
                Text(NSLocalizedString("Single task", comment: "Execute tasks"))
                    .modifier(Tagheading(.title2, .leading))
                    .foregroundColor(Color.blue)
            }

            Spacer()
        }
    }
}
