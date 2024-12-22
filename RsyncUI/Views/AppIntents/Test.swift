//
//  Test.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/12/2024.
//

import AppIntents

struct TestAppIntent: AppIntent {
    static let title: LocalizedStringResource = "Profiles"
    static let description: LocalizedStringResource = "Show all profiles"

    /// Launch your app when the system triggers this intent.
    static let openAppWhenRun: Bool = true

    @Parameter(
        title: "Profiles",
        description: "Show all profiles",
        supportedTypeIdentifiers: ["public.image"],
        inputConnectionBehavior: .connectToPreviousIntentResult
    )
    var fileURLs: [IntentFile]?

    /// Define the method that the system calls when it triggers this event.
    @MainActor
    func perform() async throws -> some IntentResult {
        if let fileURLs = fileURLs?.compactMap(\.fileURL), !fileURLs.isEmpty {
            print("test 1")
            /// Import and handle file URLs
        }
        print("test 2")
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
                "Show all profiles \(.applicationName)",
            ],
            shortTitle: "Show profiles",
            systemImageName: "arrow.up.circle.fill"
        )
    }
}
