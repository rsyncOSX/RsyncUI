//
//  AboutPanelCommand.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 08/12/2023.
//

import Foundation
import SwiftUI

public struct AboutPanelCommand: Commands {
    public init(
        title: String,
        applicationName: String = Bundle.main.bundleIdentifier ?? "",
        credits: String? = nil
    ) {
        let options: [NSApplication.AboutPanelOptionKey: Any]
        if let credits {
            options = [
                .applicationName: applicationName,
                .credits: NSAttributedString(
                    string: credits,
                    attributes: [
                        .foregroundColor: NSColor.secondaryLabelColor,
                        .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                    ]
                ),
            ]
        } else {
            options = [.applicationName: applicationName]
        }
        self.init(title: title, options: options)
    }

    public init(
        title: String,
        options: [NSApplication.AboutPanelOptionKey: Any]
    ) {
        self.title = title
        self.options = options
    }

    private let title: String
    private let options: [NSApplication.AboutPanelOptionKey: Any]

    public var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button(title) {
                NSApplication.shared
                    .orderFrontStandardAboutPanel(options: options)
            }
        }
    }
}
