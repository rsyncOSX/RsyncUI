//
//  ExecuteCommands.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/06/2021.
//

import SwiftUI

struct ExecuteCommands: Commands {
    @FocusedBinding(\.configuration) private var configuration: Configuration?

    var body: some Commands {
        CommandMenu("Execute") {
            Button(action: {
                //
            }) {
                Text("Estimate")
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])

            Divider()

            Button(action: {
                //
            }) {
                Text("Execute")
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
        }

        CommandMenu("Schedule") {
            Button(action: {
                let running = Running()
                guard running.informifisrsyncshedulerunning() == false else { return }
                NSWorkspace.shared.open(URL(fileURLWithPath: (SharedReference.shared.pathrsyncschedule ?? "/Applications/")
                        + SharedReference.shared.namersyncschedule))
                NSApp.terminate(self)
            }) {
                Text("Scheduled tasks")
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
        }
    }
}

extension FocusedValues {
    var configuration: Binding<Configuration>? {
        get { self[ConfigurationKey.self] }
        set { self[ConfigurationKey.self] = newValue }
    }

    private struct ConfigurationKey: FocusedValueKey {
        typealias Value = Binding<Configuration>
    }
}
