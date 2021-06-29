//
//  Sshcopykey.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/03/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct Sshcopykey: View {
    @Binding var selectedlogin: UniqueserversandLogins?
    @Binding var isPresented: Bool

    var body: some View {
        HStack {
            if copystring.isEmpty {
                Text("Select")
                    .padding(10)
                    .border(Color.gray)
            } else {
                Text(copystring)
                    .padding(10)
                    .border(Color.gray)
                    .textSelection(.enabled)
            }
        }

        Spacer()
    }

    var copystring: String {
        if let login = selectedlogin {
            return SshKeys().copylocalpubrsakeyfile(remote: login)
        } else {
            return ""
        }
    }
}
