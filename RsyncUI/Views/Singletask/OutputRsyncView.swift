//
//  OutputView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 12/01/2021.
//

import SwiftUI

struct OutputRsyncView: View {
    // @Binding var config: Configuration?
    @Binding var isPresented: Bool
    @Binding var output: [Outputrecord]?

    @State private var selection: Outputrecord?

    var body: some View {
        VStack {
            Text(NSLocalizedString("Output from rsync", comment: "OutputRsyncView"))
                .font(.title2)
                .padding()

            List(output ?? [], id: \.self, selection: $selection) { record in
                Text(record.line)
                    .modifier(FixedTag(750, .leading))
            }

            Spacer()

            HStack {
                Spacer()

                Button(NSLocalizedString("Dismiss", comment: "Dismiss button")) { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
    }

    func dismissview() {
        isPresented = false
    }
}
