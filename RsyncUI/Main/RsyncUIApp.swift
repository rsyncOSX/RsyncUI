//
//  RsyncUIApp.swift
//
//  Created by Thomas Evensen on 12/01/2021.
//
// swiftlint:disable multiple_closures_with_trailing_closure

import OSLog
import SwiftUI
import UserNotifications

@main
struct RsyncUIApp: App {
    @State private var selectedprofile: String? = SharedReference.shared.defaultprofile
    @State private var importtasks: Bool = false
    @State private var exporttasks: Bool = false

    var body: some Scene {
        Window("RsyncUI", id: "main") {
            RsyncUIView(selectedprofile: $selectedprofile)
                .task {
                    Homepath().createrootprofilecatalog()
                }
                .frame(minWidth: 1100, idealWidth: 1300, minHeight: 510)
        }
        .commands {
            SidebarCommands()

            ImportExportCommands()

            ExecuteCommands()

            SnapshotCommands()

            CommandGroup(replacing: .help) {
                Button(action: {
                    let documents = "https://rsyncui.netlify.app/"
                    NSWorkspace.shared.open(URL(string: documents)!)
                }) {
                    Text("RsyncUI help")
                }
            }
        }

        Settings {
            SidebarSettingsView()
        }
    }
}

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier!
    static let process = Logger(subsystem: subsystem, category: "process")
}

// swiftlint:enable multiple_closures_with_trailing_closure
