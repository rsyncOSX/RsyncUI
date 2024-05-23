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
    @State private var estimateprogressdetails = EstimateProgressDetails()
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()

    var body: some Scene {
        Window("RsyncUI", id: "main") {
            RsyncUIView(selectedprofile: $selectedprofile,
                        selecteduuids: $selecteduuids,
                        estimateprogressdetails: estimateprogressdetails)
                .task {
                    CatalogProfile().createrootprofilecatalog()
                }
                .frame(minWidth: 1100, idealWidth: 1300, minHeight: 510)
        }
        .commands {
            SidebarCommands()

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

        Window("View logfile", id: "logfile") {
            NavigationLogfileView()
        }

        Window("Rsync output", id: "output") {
            OutputRsyncByUUIDView(estimateprogressdetails: estimateprogressdetails,
                                  selecteduuids: $selecteduuids)
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
