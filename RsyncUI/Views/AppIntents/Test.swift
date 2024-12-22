//
//  TestAppIntent.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/12/2024.
//

import AppIntents

struct TestAppIntent: AppIntent {
    static let title: LocalizedStringResource = "Create a Transfer"
    static let description: LocalizedStringResource = "Starts a new File Transfer"

    /// Launch your app when the system triggers this intent.
    static let openAppWhenRun: Bool = true

    @Parameter(
        title: "Files",
        description: "Files to Transfer",
        supportedTypeIdentifiers: ["public.image"],
        inputConnectionBehavior: .connectToPreviousIntentResult
    )
    var fileURLs: [IntentFile]?

    /// Define the method that the system calls when it triggers this event.
    @MainActor
    func perform() async throws -> some IntentResult {
        if let fileURLs = fileURLs?.compactMap({ $0.fileURL }), !fileURLs.isEmpty {
            /// Import and handle file URLs
        }

        /// Deeplink into the Transfer Creation page
        // DeepLinkManager.handle(TransferURLScheme.createTransferFromShareExtension)

        /// Return an empty result since we're opening the app
        return .result()
    }
}

struct TransferAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TestAppIntent(),
            phrases: [
                "Create a \(.applicationName) transfer"
            ],
            shortTitle: "Create a Transfer",
            systemImageName: "arrow.up.circle.fill"
        )
    }
}
