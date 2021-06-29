//
//  Sshverifykey.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/03/2021.
//

import SwiftUI

struct Sshverifykey: View {
    @Binding var selectedlogin: UniqueserversandLogins?
    @Binding var isPresented: Bool

    var body: some View {
        HStack {
            if verifystring.isEmpty {
                Text("Select")
                    .padding(10)
                    .border(Color.gray)
            } else {
                Text(verifystring)
                    .padding(10)
                    .border(Color.gray)
                    .textSelection(.enabled)
            }
        }

        Spacer()
    }

    var verifystring: String {
        if let login = selectedlogin {
            return SshKeys().verifyremotekey(remote: login)
        } else {
            return ""
        }
    }
}
