//
//  DeleteProfileConfirmView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 09/05/2021.
//

import SwiftUI

struct DeleteProfileConfirmView: View {
    @Binding var isPresented: Bool
    @Binding var delete: Bool

    var body: some View {
        VStack {
            header

            Spacer()

            HStack {
                Button(NSLocalizedString("Delete", comment: "Dismiss button")) {
                    delete = true
                    dismissview()
                }
                .buttonStyle(AbortButtonStyle())

                Button(NSLocalizedString("Cancel", comment: "Dismiss button")) {
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
            let message = NSLocalizedString("Delete profile?", comment: "Alert delete")
            Text(message)
                .modifier(Tagheading(.title2, .center))
        }
        .padding()
    }

    func dismissview() {
        isPresented = false
    }
}
