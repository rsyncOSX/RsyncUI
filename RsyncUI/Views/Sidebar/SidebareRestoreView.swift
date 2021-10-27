//
//  SidebareRestoreView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/03/2021.
//

import SwiftUI

struct SidebareRestoreView: View {
    @Binding var selectedprofile: String?

    var body: some View {
        VStack {
            headingtitle

            RestoreView()
        }
        .padding()
        /*
         .onAppear(perform: {
             if selectedprofile == nil {
                 selectedprofile = SharedReference.shared.defaultprofile
             }
         })
          */
    }

    var headingtitle: some View {
        HStack {
            VStack {
                Text("Restore")
                    .modifier(Tagheading(.title2, .leading))
                    .foregroundColor(Color.blue)
            }

            Spacer()
        }
        .padding()
    }
}
