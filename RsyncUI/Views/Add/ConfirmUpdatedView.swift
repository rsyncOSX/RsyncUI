//
//  ConfirmUpdatedView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 26/02/2021.
//

import SwiftUI

struct ConfirmUpdatedView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Text(NSLocalizedString("Update configuration completed", comment: ""))

            Spacer()

            Button(NSLocalizedString("Dismiss", comment: "Dismiss button")) { dismissview() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .frame(minWidth: 100, minHeight: 150)
    }

    func dismissview() {
        isPresented = false
    }
}
