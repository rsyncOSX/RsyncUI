//
//  Sshcopykey.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/03/2021.
//

import SwiftUI

struct Sshcopykey: View {
    @Binding var selectedlogin: UniqueserversandLogins?

    var body: some View {
        HStack {
            Button(NSLocalizedString("Copy", comment: "Copy button")) { copytopasteboard() }
                .buttonStyle(PrimaryButtonStyle())

            if copystring.isEmpty {
                Text(NSLocalizedString("Select a Unique usernames and servers", comment: ""))
                    .padding(10)
                    .border(Color.gray)
            } else {
                Text(copystring)
                    .padding(10)
                    .border(Color.gray)
            }
        }

        Spacer()
    }

    var copystring: String {
        if let login = selectedlogin {
            return Ssh().copylocalpubrsakeyfile(remote: login)
        } else {
            return ""
        }
    }

    func copytopasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(copystring, forType: .string)
    }
}
