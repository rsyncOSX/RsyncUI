//
//  Sshverifykey.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/03/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct Sshverifykey: View {
    @Binding var selectedlogin: UniqueserversandLogins?
    @Binding var isPresented: Bool

    var body: some View {
        HStack {
            Button("Copy") { copytopasteboard() }
                .buttonStyle(PrimaryButtonStyle())

            if verifystring.isEmpty {
                Text("Select")
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
            return SshKeys().verifyremotekey(remote: login)
        } else {
            return ""
        }
    }

    func copytopasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(verifystring, forType: .string)
        isPresented = false
    }
}
