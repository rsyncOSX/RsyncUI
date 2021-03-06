//
//  OutputView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 12/01/2021.
//

import SwiftUI

struct OutputRsyncView: View {
    @Binding var config: Configuration?
    @Binding var isPresented: Bool
    @Binding var output: [Outputrecord]?

    var body: some View {
        VStack {
            Section(header: header) {
                List(output ?? []) { record in
                    Text(record.line)
                        .modifier(FixedTag(750, .leading))
                }
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

    var header: some View {
        Text("Output")
            .modifier(FixedTag(200, .center))
    }

    func dismissview() {
        isPresented = false
    }
}
