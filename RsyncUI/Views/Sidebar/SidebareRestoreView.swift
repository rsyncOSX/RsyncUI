//
//  SidebareRestoreView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/03/2021.
//

import SwiftUI

struct SidebareRestoreView: View {
    @State private var selectedconfig: Configuration?

    var body: some View {
        VStack {
            headingtitle

            RestoreView(selectedconfig: $selectedconfig)
        }
        .padding()
    }

    var headingtitle: some View {
        HStack {
            VStack {
                Text(NSLocalizedString("Restore", comment: "SidebarRsyncParameter"))
                    .modifier(Tagheading(.title2, .leading))
                    .foregroundColor(Color.blue)
            }

            Spacer()
        }
        .padding()
    }
}
