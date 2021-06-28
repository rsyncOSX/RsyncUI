//
//  DeleteProfileConfirmView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 09/05/2021.
//

import SwiftUI

struct ConfirmDeleteProfileView: View {
    @Binding var isPresented: Bool
    @Binding var delete: Bool
    @Binding var profile: String?

    var body: some View {
        VStack {
            header

            Spacer()

            HStack {
                Button("Delete") {
                    delete = true
                    dismissview()
                }
                .buttonStyle(AbortButtonStyle())

                Button("Cancel") {
                    delete = false
                    dismissview()
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

    func dismissview() {
        isPresented = false
    }
}
