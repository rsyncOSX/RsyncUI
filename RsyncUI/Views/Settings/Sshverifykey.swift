//
//  Sshverifykey.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/03/2021.
//

import SwiftUI

struct Sshverifykey: View {
    @Binding var selectedlogin: UniqueserversandLogins?

    var body: some View {
        HStack {
            Button(NSLocalizedString("Copy", comment: "Verify button")) { copytopasteboard() }
                .buttonStyle(PrimaryButtonStyle())

            if verifystring.isEmpty {
                Text(NSLocalizedString("Select a Unique usernames and servers", comment: ""))
                    .padding(10)
                    .border(Color.gray)
            } else {
                Text(verifystring)
                    .padding(10)
                    .border(Color.gray)
            }
        }

        Spacer()
    }

    var verifystring: String {
        if let login = selectedlogin {
            return Ssh().verifyremotekey(remote: login)
        } else {
            return ""
        }
    }

    func copytopasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(verifystring, forType: .string)
    }
}
