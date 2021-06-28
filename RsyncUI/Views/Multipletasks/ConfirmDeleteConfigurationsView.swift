//
//  DeleteConfigurationsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 12/02/2021.
//

import SwiftUI

struct ConfirmDeleteConfigurationsView: View {
    @Binding var isPresented: Bool
    @Binding var delete: Bool
    @Binding var selecteduuids: Set<UUID>

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
                + " \(selecteduuids.count)"
                + " configuration(s)?"
            Text(message)
                .modifier(Tagheading(.title2, .center))
        }
        .padding()
    }

    func dismissview() {
        isPresented = false
    }
}
