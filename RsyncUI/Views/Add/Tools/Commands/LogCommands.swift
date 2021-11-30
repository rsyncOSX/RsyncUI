//
//  LogCommands.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 30/11/2021.
//

import SwiftUI

struct LogCommands: Commands {
    @FocusedBinding(\.selectlog) private var selectlog

    @Binding var viewlogfile: Bool

    var body: some Commands {
        CommandMenu("Logfile") {
            Button(action: {
                presentlogfile()
            }) {
                Text("View logfile")
            }
            .keyboardShortcut("o", modifiers: [.command])

            SelectLog(selectlog: $selectlog)
        }
    }

    func presentlogfile() {
        viewlogfile = true
    }
}

struct SelectLog: View {
    @Binding var selectlog: Bool?

    var body: some View {
        Button {
            selectlog = true
        } label: {
            Label("Select log", systemImage: "play.fill")
        }
        .keyboardShortcut("l", modifiers: [.command])
    }
}

struct FocusedSelectlog: FocusedValueKey {
    typealias Value = Binding<Bool>
}

extension FocusedValues {
    var selectlog: FocusedSelectlog.Value? {
        get { self[FocusedSelectlog.self] }
        set { self[FocusedSelectlog.self] = newValue }
    }
}
