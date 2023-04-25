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
    @State private var filterstring: String = ""

    var body: some View {
        ZStack {
            QuicktaskView(showcompleted: $showcompleted)
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
        .searchable(text: $filterstring)
    }
}
