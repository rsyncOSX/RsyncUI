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
                Sshcopykey(selectedlogin: $selectedlogin)

                Sshverifykey(selectedlogin: $selectedlogin)
            }

            HStack {
                Spacer()

                Button(NSLocalizedString("Dismiss", comment: "Dismiss button")) { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
    }

    func dismissview() {
        isPresented = false
    }
}
