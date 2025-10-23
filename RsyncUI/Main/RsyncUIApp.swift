//
//  RsyncUIApp.swift
//
//  Created by Thomas Evensen on 12/01/2021.
//
// swiftlint:disable multiple_closures_with_trailing_closure

import OSLog
import SwiftUI

@main
struct RsyncUIApp: App {
    @State private var showabout: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        Window("RsyncUI", id: "main") {
            RsyncUIView()
                .task {
                    Homepath().createrootprofilecatalog()
                }
                .frame(minWidth: 1100, idealWidth: 1300, minHeight: 510)
                .sheet(isPresented: $showabout) {
                    AboutView()
                }
        }
        .commands {
            SidebarCommands()

            ImportExportCommands()

            ExecuteCommands()

            SnapshotCommands()

            CommandGroup(replacing: .help) {
                Button(action: {
                    let documents = "https://rsyncui.netlify.app/docs/"
                    NSWorkspace.shared.open(URL(string: documents)!)
                }) {
                    Text("RsyncUI documentation")
                }
            }

            CommandGroup(replacing: .appInfo) {
                Button(action: {
                    showabout = true
                }) {
                    Text("About RsyncUI")
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                // App is going to background - execute your cleanup task
                performCleanupTask()
            }
        }

        Settings {
            SidebarSettingsView()
        }
    }

    private func performCleanupTask() {
        Logger.process.info("RsyncUIApp: performCleanupTask(), RsyncUI shutting down, doing clean up")
        GlobalTimer.shared.invalidateAllSchedulesAndTimer()
    }
}

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier!
    static let process = Logger(subsystem: subsystem, category: "process")
}

// swiftlint:enable multiple_closures_with_trailing_closure
