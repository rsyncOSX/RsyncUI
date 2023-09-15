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

    @StateObject private var actions = Actions()

    var body: some Scene {
        WindowGroup {
            RsyncUIView(selectedprofile: $selectedprofile, actions: actions)
                .task {
                    CatalogProfile().createrootprofilecatalog()
                    ReadUserConfigurationJSON()
                }
                .sheet(isPresented: $viewlogfile) { LogfileView(action: actions) }
                .frame(minWidth: 1300, minHeight: 510)
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
            SettingsView(selectedprofile: $selectedprofile)
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

struct ActionHolder: Hashable, Identifiable {
    let id = UUID()
    var timestamp: Date = .init()
    var action: String
    var actionnumber: Int?
    var profile: String
    var source: String
}

final class Actions: ObservableObject {
    var actions = Set<ActionHolder>()

    func addaction(_ action: ActionHolder) {
        var actioninsert: ActionHolder
        actioninsert = action
        actioninsert.actionnumber = actions.count
        actions.insert(actioninsert)
    }

    func resetactions() {
        actions.removeAll()
    }

    func getactions() -> [ActionHolder] {
        var privateactions = [ActionHolder]()
        for action in actions {
            privateactions.append(action)
        }
        return privateactions.sorted { $0.actionnumber ?? -1 < $1.actionnumber ?? -1 }
    }
}

// swiftlint:enable multiple_closures_with_trailing_closure
