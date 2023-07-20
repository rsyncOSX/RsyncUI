//
//  DeleteProfileConfirmView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 09/05/2021.
//

import SwiftUI

struct ConfirmDeleteProfileView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
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
                .buttonStyle(AbortButtonStyle())

                Button("Cancel") {
                    delete = false
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
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
                .modifier(Tagheading(.title2, .center))
        }
        .padding()
    }
}
