//
//  AppDelegate.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 12/01/2021.
//
// swiftlint:disable multiple_closures_with_trailing_closure

import SwiftUI
import UserNotifications

@main
struct RsyncUIApp: App {
    @State private var viewlogfile: Bool = false
    @StateObject var getrsyncversion = GetRsyncversion()
    @StateObject var checkfornewversionofrsyncui = NewversionJSON()

    var body: some Scene {
        WindowGroup {
            RsyncUIView()
                .environmentObject(getrsyncversion)
                .environmentObject(checkfornewversionofrsyncui)
                .onAppear {
                    // User notifications
                    setusernotifications()
                    // Create base profile catalog
                    // Read user settings
                    // Check if schedule app is running
                    CatalogProfile().createrootprofilecatalog()
                    ReadUserConfigurationPLIST()
                    Running()
                }
                .sheet(isPresented: $viewlogfile) { LogfileView(viewlogfile: $viewlogfile) }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        getrsyncversion.update(SharedReference.shared.rsyncversion3)
                    }
                }
        }
        .commands {
            SidebarCommands()
            ExecuteCommands()

            CommandMenu(NSLocalizedString("Logfile", comment: "RsyncUIApp")) {
                Button(action: {
                    presentlogfile()
                }) {
                    Text(NSLocalizedString("View logfile", comment: "RsyncUIApp"))
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
        }
        Settings {
            SidebarSettingsView()
                .environmentObject(getrsyncversion)
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

    func presentlogfile() {
        viewlogfile = true
    }
}
