//
//  ConfirmView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 26/02/2021.
//

import SwiftUI

struct ConfirmAddView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Text("Add configuration completed")

            Spacer()

            Button("Dismiss") { dismissview() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .frame(minWidth: 100, minHeight: 150)
    }

    func dismissview() {
        isPresented = false
    }
}
