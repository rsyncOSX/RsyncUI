//
//  LogCommands.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 30/11/2021.
//

import SwiftUI

struct LogCommands: Commands {
    @FocusedBinding(\.selecttask) private var selectttask

    @Binding var viewlogfile: Bool

    var body: some Commands {
        CommandMenu("Logfile") {
            Button(action: {
                presentlogfile()
            }) {
                Text("View logfile")
            }
            .keyboardShortcut("o", modifiers: [.command])

            SelectTask(selecttask: $selectttask)
        }
    }

    func presentlogfile() {
        viewlogfile = true
    }
}
