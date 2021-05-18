//
//  ConfirmDeleteSnapshots.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/05/2021.
//

import SwiftUI

struct ConfirmDeleteSnapshots: View {
    @Binding var isPresented: Bool
    @Binding var delete: Bool
    @Binding var uuidstodelete: Set<UUID>?

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
            let message = NSLocalizedString("Delete", comment: "Alert delete")
                + " \(uuidstodelete?.count ?? 0)" + " "
                + NSLocalizedString("snapshot(s)", comment: "Alert delete")
                + "?"
            Text(message)
                .modifier(Tagheading(.title2, .center))
        }
        .padding()
    }

    func dismissview() {
        isPresented = false
    }
}
