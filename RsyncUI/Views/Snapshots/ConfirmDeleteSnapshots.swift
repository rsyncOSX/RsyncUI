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
            let message = "Delete"
                + " \(uuidstodelete?.count ?? 0)" + " "
                + "snapshot(s)"
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
