//
//  SidebarQuicktaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/07/2021.
//

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
            VStack(alignment: .leading) {
                Text("Quick synchronize")
                    .modifier(Tagheading(.title2, .leading))
                    .foregroundColor(Color.blue)
            }

            Spacer()
        }
        .padding()
    }
}
