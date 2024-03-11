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
        .onChange(of: selectedprofile) {
            if selectedprofile == SharedReference.shared.demprofile {
                SharedReference.shared.demodata = true
                Logger.process.info("Demodata is TRUE")
                Task {
                    let data = await DemoDataJSONSnapshots().getsnapshots()
                    SharedReference.shared.demodataprocesstermination = data
                    Logger.process.info("Demodata is SET")
                }

            } else {
                SharedReference.shared.demodata = false
                Logger.process.info("Demodata is FALSE")
                SharedReference.shared.demodataprocesstermination = nil
            }
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
        }

        Settings {
            SettingsView()
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

extension Logger: @unchecked Sendable {
    private static let subsystem = Bundle.main.bundleIdentifier!
    static let process = Logger(subsystem: subsystem, category: "process")
}

// swiftlint:enable multiple_closures_with_trailing_closure
