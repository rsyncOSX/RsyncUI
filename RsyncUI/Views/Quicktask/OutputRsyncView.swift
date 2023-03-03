//
//  OutputRsyncView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/10/2022.
//

import SwiftUI

struct OutputRsyncView: View {
    @Binding var isPresented: Bool

    var output: [String]

    @State private var selection: String?

    var body: some View {
        VStack {
            Text("Output from rsync")
                .font(.title2)
                .padding()

            List(listitems, id: \.self, selection: $selection) { line in Text(line)
                .modifier(FixedTag(750, .leading))
            }

            Spacer()

            HStack {
                Spacer()

                Button("Dismiss") { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
    }

    var listitems: [String] { return output }

    func dismissview() {
        isPresented = false
    }
}
