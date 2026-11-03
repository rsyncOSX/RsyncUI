//
//  ButtonStyles.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/03/2021.
//

import SwiftUI

/// The rounded text-input appearance on both macOS 14 and newer systems.
struct AdaptiveRoundedTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 27.0, *) {
            content
                .textFieldStyle(.bordered)
                .textInputBorderShape(.roundedRectangle)
        } else {
            content.textFieldStyle(.roundedBorder)
        }
    }
}

/// A primary action button with a bordered fallback before macOS 26.
struct AdaptiveProminentButton: View {
    let systemImage: String
    let text: LocalizedStringKey?
    let helpText: LocalizedStringKey
    var textcolor: Bool = false
    let action: () -> Void

    init(
        systemImage: String,
        text: LocalizedStringKey? = nil,
        helpText: LocalizedStringKey,
        textcolor: Bool = false,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.text = text
        self.helpText = helpText
        self.textcolor = textcolor
        self.action = action
    }

    var body: some View {
        if #available(macOS 26.0, *) {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.borderedProminent)
        }
    }

    private var button: some View {
        Button(action: action) {
            if systemImage.isEmpty {
                if let text {
                    Text(text)
                        .foregroundStyle(textcolor ? .green : .primary)
                }
            } else {
                Label {
                    if let text {
                        Text(text)
                            .foregroundStyle(textcolor ? .green : .primary)
                    }
                } icon: {
                    Image(systemName: systemImage)
                }
            }
        }
        .help(helpText)
    }
}

/// A close button using the semantic close role when available.
struct AdaptiveCloseButton: View {
    let action: () -> Void

    var body: some View {
        if #available(macOS 26.0, *) {
            Button("Close", role: .close, action: action)
                .buttonStyle(.glass)
        } else {
            Button("Close", action: action)
                .buttonStyle(.bordered)
        }
    }
}
