//
//  ConfirmDeleteSnapshots.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/05/2021.
//

import SwiftUI

struct ConfirmDeleteSnapshots: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    @Binding var delete: Bool
    var snapshotuuidsfordelete: Set<LogrecordSnapshot.ID>

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
            let message = "Delete"
                + " \(snapshotuuidsfordelete.count)" + " "
                + "snapshot(s)"
                + "?"
            Text(message)
                .font(.title2)
        }
        .padding()
    }
}
