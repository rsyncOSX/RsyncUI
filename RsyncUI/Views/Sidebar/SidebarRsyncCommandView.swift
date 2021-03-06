//
//  SidebarRsyncParametersView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/02/2021.
//

import SwiftUI

struct SidebarRsyncCommandView: View {
    var body: some View {
        VStack {
            headingtitle

            RsyncCommandView()
        }
        .padding()
    }

    var headingtitle: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(NSLocalizedString("Rsync commands", comment: "Execute tasks"))
                    .modifier(Tagheading(.title2, .leading))
                    .foregroundColor(Color.blue)
            }

            Spacer()
        }
        .padding()
    }
}
