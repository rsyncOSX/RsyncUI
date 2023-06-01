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
                .frame(minWidth: 1250, minHeight: 510)
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

struct ActionHolder: Hashable {
    var timestamp: Date = .init()
    var action: String
    var actionnumber: Int?
    var profile: String
}

final class Actions: ObservableObject {
    @Published var output = [Data]()

    struct Data: Identifiable {
        let id = UUID()
        var line: String
    }

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

    func generatedata() {
        output = [Data]()
        for value in actions {
            let number = String(value.actionnumber ?? 0)
            let line = value.profile + " " + number + ": " + value.timestamp.localized_string_from_date() + " " + value.action
            let data = Data(line: line)
            output.append(data)
        }
    }
}

// swiftlint:enable multiple_closures_with_trailing_closure
