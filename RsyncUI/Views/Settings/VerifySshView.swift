//
//  VerifySshView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/03/2021.
//

import SwiftUI

struct VerifySshView: View {
    @Binding var selectedlogin: UniqueserversandLogins?
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Section(header: header) {
                    Sshcopykey(selectedlogin: $selectedlogin, isPresented: $isPresented)

                    Sshverifykey(selectedlogin: $selectedlogin, isPresented: $isPresented)
                }
            }

            HStack {
                Spacer()

                Button(NSLocalizedString("Dismiss", comment: "Dismiss button")) { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
    }

    // Paths
    var header: some View {
        Text(NSLocalizedString("Copy and paste commands", comment: "ssh settings"))
    }

    func dismissview() {
        isPresented = false
    }
}
