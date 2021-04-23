//
//  SidebarRsyncParameter.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/03/2021.
//

import SwiftUI

struct SidebarRsyncParameter: View {
    @Binding var reload: Bool
    @State private var updated = false
    @State private var showdetails = false

    var body: some View {
        VStack {
            headingtitle

            if showdetails == false {
                RsyncParametersView(reload: $reload, updated: $updated, showdetails: $showdetails)
            } else {
                DetailedRsyncParametersView(reload: $reload, updated: $updated, showdetails: $showdetails)
            }
        }
        .padding()
    }

    var headingtitle: some View {
        HStack {
            VStack {
                Text(NSLocalizedString("Rsync parameters", comment: "SidebarRsyncParameter"))
                    .modifier(Tagheading(.title2, .leading))
                    .foregroundColor(Color.blue)
            }

            Spacer()
        }
        .padding()
    }
}
