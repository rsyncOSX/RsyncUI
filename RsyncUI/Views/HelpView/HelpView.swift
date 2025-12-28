//
//  HelpView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 09/05/2025.
//
// swiftlint:disable line_length

import SwiftUI

struct HelpView: View {
   
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
                VStack(alignment: .leading, spacing: 16) {
                    Text("About the --delete Parameter")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("As a safety precaution, the --delete parameter is not set by default when adding new tasks.")
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("The --delete parameter ensures complete synchronization between source and destination by removing files at the destination that no longer exist in the source.")
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Important for New Users")
                                .font(.body)
                                .fontWeight(.semibold)

                            Text("If you are new to rsync, please read the Important and Limitations sections in the RsyncUI documentation before enabling this parameter.")
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
            }
        }
        .padding()
        .frame(maxWidth: 420)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// swiftlint:enable line_length
