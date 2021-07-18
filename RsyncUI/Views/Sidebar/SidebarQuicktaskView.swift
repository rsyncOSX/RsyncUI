//
//  SidebarQuicktaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/07/2021.
//

import AlertToast
import SwiftUI

struct SidebarQuicktaskView: View {
    // Show completed
    @State private var showcompleted: Bool = false

    var body: some View {
        ZStack {
            VStack {
                headingtitle

                QuicktaskView(showcompleted: $showcompleted)
            }
            .padding()

            if showcompleted {
                AlertToast(type: .complete(Color.green),
                           title: Optional("Completed"), subTitle: Optional(""))
                    .onAppear(perform: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showcompleted = false
                        }
                    })
            }
        }
    }

    var headingtitle: some View {
        HStack {
            imagerssync

            VStack(alignment: .leading) {
                Text("Quick task")
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
