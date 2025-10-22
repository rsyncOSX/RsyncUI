//
//  VerifyRemoteCommands.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/10/2025.
//

import SwiftUI

struct VerifyRemoteCommands: Commands {
    @FocusedBinding(\.verifyremote) private var verifyremote

    var body: some Commands {
        CommandMenu("Verify Remote") {
            VerifyRemote(verifyremote: $verifyremote)
        }
    }
}

struct VerifyRemote: View {
    @Binding var verifyremote: Bool?

    var body: some View {
        Button {
            verifyremote = true
        } label: {
            Text("Verify")
        }
        .keyboardShortcut("z", modifiers: [.command])
    }
}

struct FocusedVerifyRemote: FocusedValueKey {
    typealias Value = Binding<Bool>
}

extension FocusedValues {
    var verifyremote: FocusedVerifyRemote.Value? {
        get { self[FocusedVerifyRemote.self] }
        set { self[FocusedVerifyRemote.self] = newValue }
    }
}
