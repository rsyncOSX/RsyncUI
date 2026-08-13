//
//  ButtonStyles.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/03/2021.
//

import SwiftUI

/// A primary action button that adopts native Liquid Glass on macOS 26 and
/// retains the established prominent appearance on earlier macOS releases.
struct AdaptiveProminentButton: View {
    let systemImage: String
    let text: String?
    let helpText: String
    var textcolor: Bool = false
    let action: () -> Void

    init(
        systemImage: String,
        text: String? = nil,
        helpText: String,
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
            button
                .buttonStyle(.glassProminent)
        } else {
            button
                .buttonStyle(.borderedProminent)
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

/// A close button that uses the semantic close role where it is available.
struct AdaptiveCloseButton: View {
    let action: () -> Void

    var body: some View {
        if #available(macOS 26.0, *) {
            Button("Close", role: .close, action: action)
                .buttonStyle(.glass)
        } else {
            Button("Close", action: action)
                .buttonStyle(.borderedProminent)
        }
    }
}
