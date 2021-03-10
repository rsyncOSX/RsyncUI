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
        Text(NSLocalizedString("Verify SSH", comment: "ssh settings"))
            .font(.title2)
            .padding()

        VStack {
            VStack(alignment: .leading) {
                Section(header: header) {
                    Sshcopykey(selectedlogin: $selectedlogin, isPresented: $isPresented)

                    Sshverifykey(selectedlogin: $selectedlogin, isPresented: $isPresented)
                }
            }

            HStack {
                Spacer()

                Button(NSLocalizedString("Dismiss", comment: "ssh settings")) { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
    }

    // Paths
    var header: some View {
        Text(NSLocalizedString("Copy and paste commands in terminal to verify", comment: "ssh settings"))
    }

    func dismissview() {
        isPresented = false
    }
}
