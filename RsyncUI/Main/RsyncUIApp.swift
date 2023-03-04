//
//  RsyncUIApp.swift
//
//  Created by Thomas Evensen on 12/01/2021.
//
// swiftlint:disable multiple_closures_with_trailing_closure

import SwiftUI
import UserNotifications

@main
struct RsyncUIApp: App {
    @State private var viewlogfile: Bool = false
    @State private var selectedprofile: String? = "Default profile"

    var body: some Scene {
        WindowGroup {
            RsyncUIView(selectedprofile: $selectedprofile)
                .task {
                    CatalogProfile().createrootprofilecatalog()
                    ReadUserConfigurationJSON()
                }
                .sheet(isPresented: $viewlogfile) { LogfileView(viewlogfile: $viewlogfile) }
                .frame(minWidth: 1350, minHeight: 505)
        }
        .commands {
            SidebarCommands()
            ExecuteCommands()
            LogCommands(viewlogfile: $viewlogfile)
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
            SidebarSettingsView(selectedprofile: $selectedprofile)
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
