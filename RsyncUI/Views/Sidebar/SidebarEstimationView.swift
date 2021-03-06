//
//  EstimationView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import SwiftUI

struct SidebarEstimationView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @State private var selectedconfig: Configuration?
    @Binding var reload: Bool

    var body: some View {
        VStack {
            headingtitle

            EstimationView(selectedconfig: $selectedconfig.onChange {},
                           reload: $reload)
        }

        .padding()
    }

    var headingtitle: some View {
        HStack {
            ImageRsync()

            VStack(alignment: .leading) {
                Text(NSLocalizedString("Multiple tasks", comment: "Execute tasks"))
                    .modifier(Tagheading(.title2, .leading))
                    .foregroundColor(Color.blue)
            }

            Spacer()
        }
    }
}
