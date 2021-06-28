//
//  SidebarRsyncParameter.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/03/2021.
//

import SwiftUI

struct SidebarRsyncParameter: View {
    @Binding var reload: Bool
    @State private var showdetails = false
    @State private var selectedconfig: Configuration?

    var body: some View {
        VStack(alignment: .leading) {
            if showdetails == false {
                headingtitle

                RsyncParametersView(reload: $reload,
                                    showdetails: $showdetails,
                                    selectedconfig: $selectedconfig)
            } else {
                VStack(alignment: .leading) {
                    headingtitle

                    PresentOneconfigView(config: $selectedconfig)
                }

                DetailedRsyncParametersView(reload: $reload,
                                            showdetails: $showdetails,
                                            selectedconfig: $selectedconfig)
            }
        }
        .padding()
    }

    var headingtitle: some View {
        HStack {
            VStack {
                Text("Rsync parameters")
                    .modifier(Tagheading(.title2, .leading))
                    .foregroundColor(Color.blue)
            }

            Spacer()
        }
        .padding()
        .frame(width: 200)
    }
}
