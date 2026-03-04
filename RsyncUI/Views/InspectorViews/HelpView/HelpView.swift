//
//  HelpView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 09/05/2025.
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    let text: String

    var body: some View {
        VStack(spacing: 20) {
            Text(text)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()

            Spacer()

            if #available(macOS 26.0, *) {
                Button("Close", role: .close) {
                    dismiss()
                }
                .buttonStyle(RefinedGlassButtonStyle())
            } else {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "return")
                }
                .help("Close")
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: 500)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct HelpSectionView: View {
    @Binding var showhelp: Bool
    @Binding var whichhelptext: Int

    let deleteparameterpresent: Bool

    var body: some View {
        if deleteparameterpresent {
            HStack {
                Text("If \(Text("red Synchronize ID").foregroundColor(.red)) click")
                Button { whichhelptext = 1; showhelp.toggle() }
                    label: { Image(systemName: "questionmark.circle") }
                    .buttonStyle(HelpButtonStyle(redorwhitebutton: deleteparameterpresent))
                Text("for more information")
            }
            .padding(.bottom, 10)
        } else {
            HStack {
                Text("To add --delete click")
                Button { whichhelptext = 2; showhelp.toggle() }
                    label: { Image(systemName: "questionmark.circle") }
                    .buttonStyle(HelpButtonStyle(redorwhitebutton: deleteparameterpresent))
                Text("for more information")
            }
            .padding(.bottom, 10)
        }
    }
}
