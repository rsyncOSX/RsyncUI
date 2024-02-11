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

    var body: some Scene {
        Window("RsyncUI", id: "main") {
            RsyncUIView(selectedprofile: $selectedprofile)
                .task {
                    CatalogProfile().createrootprofilecatalog()
                    ReadUserConfigurationJSON()
                }
                .frame(minWidth: 1300, minHeight: 510)
        }
        .commands {
            SidebarCommands()

            ExecuteCommands()

            SnapshotCommands()

            CommandGroup(replacing: .help) {
                Button(action: {
                    let documents: String = "https://rsyncui.netlify.app/"
                    NSWorkspace.shared.open(URL(string: documents)!)
                }) {
                    Text("RsyncUI help")
                }
            }

            AboutPanelCommand(
                title: "About RsyncUI",
                credits: "This app was created by SwiftUI\n https.//rsyncui.netlify.app"
            )
        }

        Settings {
            // TODO:
            SettingsView(configurations: [])
        }
    }

    func setusernotifications() {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        center.requestAuthorization(options: options) { granted, _ in
            if granted {
                // application.registerForRemoteNotifications()
            }
        }
    }
}

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let process = Logger(subsystem: subsystem, category: "process")
}

// swiftlint:enable multiple_closures_with_trailing_closure
