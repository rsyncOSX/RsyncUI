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
                + " \(selecteduuids.count)"
                + NSLocalizedString(" configuration(s)?", comment: "Alert delete")
            Text(message)
                .modifier(Tagheading(.title2, .center))
        }
        .padding()
    }

    func dismissview() {
        isPresented = false
    }
}
