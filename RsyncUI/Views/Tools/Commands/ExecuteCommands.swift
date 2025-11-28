//
//  ExecuteCommands.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/06/2021.
//

import SwiftUI

struct ExecuteCommands: Commands {
    @FocusedBinding(\.startestimation) private var startestimation
    @FocusedBinding(\.startexecution) private var startexecution
    @FocusedBinding(\.aborttask) private var aborttask
    @FocusedBinding(\.showquicktask) private var showquicktask

    var body: some Commands {
        CommandMenu("Tasks") {
            StarteestimateButton(startestimation: $startestimation)
            StartexecuteButton(startexecution: $startexecution)

            Divider()

            Abborttask(aborttask: $aborttask)

            Divider()

            ShowQuicktask(showquicktask: $showquicktask)
        }
    }
}

struct StarteestimateButton: View {
    @Binding var startestimation: Bool?

    var body: some View {
        Button {
            startestimation = true
        } label: {
            Text("Estimate")
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
            Text("Synchronize")
        }
        .keyboardShortcut("r", modifiers: [.command])
    }
}

struct Abborttask: View {
    @Binding var aborttask: Bool?

    var body: some View {
        Button {
            aborttask = true
        } label: {
            Text("Abort task")
        }
        .keyboardShortcut("k", modifiers: [.command])
    }
}

struct ShowQuicktask: View {
    @Binding var showquicktask: Bool?

    var body: some View {
        if show {
            Button {
                showquicktask = true
            } label: {
                Text("Show Quick & Chart")
            }
            .keyboardShortcut("s", modifiers: [.command])
        } else {
            Button {
                showquicktask = false
            } label: {
                Text("Hide Quick & Chart")
            }
            .keyboardShortcut("s", modifiers: [.command])
        }
    }

    var show: Bool {
        if showquicktask == false {
            true
        } else {
            false
        }
    }
}

struct FocusedShowQuicktaskBinding: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct FocusedEstimateBinding: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct FocusedExecuteBinding: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct FocusedAborttask: FocusedValueKey {
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

    var aborttask: FocusedAborttask.Value? {
        get { self[FocusedAborttask.self] }
        set { self[FocusedAborttask.self] = newValue }
    }

    var showquicktask: FocusedShowQuicktaskBinding.Value? {
        get { self[FocusedShowQuicktaskBinding.self] }
        set { self[FocusedShowQuicktaskBinding.self] = newValue }
    }
}
