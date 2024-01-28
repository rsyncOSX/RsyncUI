//
//  ConfirmDeleteProfileView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 09/05/2021.
//

import SwiftUI

struct ConfirmDeleteProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var delete: Bool
    var profile: String?

    var body: some View {
        VStack {
            header

            Spacer()

            HStack {
                Button("Delete") {
                    delete = true
                    dismiss()
                }
                .buttonStyle(ColorfulRedButtonStyle())

                Button("Cancel") {
                    delete = false
                    dismiss()
                }
                .buttonStyle(ColorfulButtonStyle())
            }
            .padding()
        }
        .padding()
    }

    var header: some View {
        HStack {
            let message = "Delete profile"
                + ": " + (profile ?? "") + "?"
            Text(message)
                .font(.title2)
        }
        .padding()
    }
}
