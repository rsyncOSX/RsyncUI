//
//  LogCommands.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 30/11/2021.
//

import SwiftUI

struct LogCommands: Commands {
    @Binding var viewlogfile: Bool

    var body: some Commands {
        CommandMenu("Logfile") {
            Button(action: {
                if SharedReference.shared.usenavigationstack == false {
                    presentlogfile()
                }
            }) {
                Text("View logfile")
            }
            .keyboardShortcut("o", modifiers: [.command])
        }
    }

    func presentlogfile() {
        viewlogfile = true
    }
}
