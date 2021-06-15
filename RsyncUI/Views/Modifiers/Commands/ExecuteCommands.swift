//
//  ExecuteCommands.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/06/2021.
//
// swiftlint:disable multiple_closures_with_trailing_closure line_length

import SwiftUI

struct ExecuteCommands: Commands {
    @FocusedBinding(\.startestimation) private var startestimation
    @FocusedBinding(\.startexecution) private var startexecution

    var body: some Commands {
        CommandMenu("Execute") {
            StarteestimateButton(startestimation: $startestimation)
            StartexecuteButton(startexecution: $startexecution)
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

struct StarteestimateButton: View {
    @Binding var startestimation: Bool?

    var body: some View {
        Button {
            startestimation = true
        } label: {
            Label("Estimate", systemImage: "drop")
        }
        .keyboardShortcut("e", modifiers: [.command])
    }
}

struct StartexecuteButton: View {
    @Binding var startexecution: Bool?

    var body: some View {
        Button {
            startexecution = true
        } label: {
            Label("Execute", systemImage: "drop")
        }
        .keyboardShortcut("r", modifiers: [.command])
    }
}

struct FocusedEstimateBinding: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct FocusedExecuteBinding: FocusedValueKey {
    typealias Value = Binding<Bool>
}

extension FocusedValues {
    var startestimation: FocusedEstimateBinding.Value? {
        get { self[FocusedEstimateBinding.self] }
        set { self[FocusedEstimateBinding.self] = newValue }
    }

    var startexecution: FocusedExecuteBinding.Value? {
        get { self[FocusedExecuteBinding.self] }
        set { self[FocusedExecuteBinding.self] = newValue }
    }
}
