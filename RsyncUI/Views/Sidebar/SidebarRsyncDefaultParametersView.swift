//
//  SidebarRsyncDefaultParametersView.swift
//  SidebarRsyncDefaultParametersView
//
//  Created by Thomas Evensen on 18/08/2021.
//

import SwiftUI

struct SidebarRsyncDefaultParametersView: View {
    @Binding var reload: Bool
    @State private var showdetails = false
    @State private var selectedconfig: Configuration?

    var body: some View {
        VStack {
            headingtitle

            RsyncDefaultParametersView(reload: $reload)
        }
    }

    var headingtitle: some View {
        HStack {
            VStack {
                Text("Rsync default parameters")
                    .modifier(Tagheading(.title2, .leading))
                    .foregroundColor(Color.blue)
            }

            Spacer()
        }
        .padding()
    }
}
