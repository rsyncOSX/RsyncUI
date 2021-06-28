//
//  SidebarSingleTasksView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 12/02/2021.
//

import SwiftUI

struct SidebarSingleTasksView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    var body: some View {
        VStack {
            headingtitle

            SingleTasksView(selectedprofile: $selectedprofile, reload: $reload)
        }

        .padding()
    }

    var headingtitle: some View {
        HStack {
            imagerssync

            VStack(alignment: .leading) {
                Text("Single task")
                    .modifier(Tagheading(.title2, .leading))
                    .foregroundColor(Color.blue)
            }

            Spacer()
        }
    }

    var imagerssync: some View {
        Image("rsync")
            .resizable()
            .aspectRatio(1.0, contentMode: .fit)
            .frame(maxWidth: 48)
            .padding(.bottom, 10)
    }
}
