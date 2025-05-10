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

    var body: some View {
        VStack(spacing: 20) {
            Text(text)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()

            Button("Dismiss") {
                dismiss()
            }
            .padding()
            .buttonStyle(ColorfulButtonStyle())
        }
        .padding()
    }
}
