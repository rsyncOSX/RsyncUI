//
//  HelpView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 09/05/2025.
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss

    let text: String
    let add: Bool
    let deleteparameterpresent: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text(text)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()

            if add {
                VStack(alignment: .leading) {
                    Text("Add --delete parameter")
                        .foregroundColor(deleteparameterpresent ? .red : .blue)
                        .font(.title2)
                }
            }

            ScrollView {
                Text("As a safety precaution, the --delete parameter is *not* set as a " +
                     "default parameter when adding new tasks. To ensure that the source " +
                     "and destination are in complete synchronization, the --delete " +
                     "parameter must be *enabled*. If you are new to `rsync`, I strongly " +
                     "recommend reading the *Important*  and *Limitations* sections in " +
                     "RsyncUI user documentation as a minimum. ")
                    .padding()
            }

            if #available(macOS 26.0, *) {
                Button("Close", role: .close) {
                    dismiss()
                }
                .buttonStyle(RefinedGlassButtonStyle())

            } else {
                Button("Close") {
                    dismiss()
                }
                .padding()
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
