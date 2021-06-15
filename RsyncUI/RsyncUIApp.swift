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
    @State private var selectedprofile: String?
    @State private var reload: Bool = false
    @State private var viewlogfile: Bool = false
    @StateObject var rsyncUIData = RsyncUIdata(profile: nil)
    @StateObject var getrsyncversion = GetRsyncversion()
    @StateObject var profilenames = Profilenames()
    @StateObject var checkfornewversionofrsyncui = NewversionJSON()

    var body: some Scene {
        WindowGroup {
            ContentView(selectedprofile: $selectedprofile, reload: $reload)
                .environmentObject(rsyncUIData)
                .environmentObject(getrsyncversion)
                .environmentObject(profilenames)
                .environmentObject(checkfornewversionofrsyncui)
                .onAppear {
                    // User notifications
                    setusernotifications()
                    // Create base profile catalog
                    CatalogProfile().createrootprofilecatalog()
                    ReadUserConfigurationPLIST()
                    Running()
                }
                .sheet(isPresented: $viewlogfile) { LogfileView(viewlogfile: $viewlogfile) }
        }

        .commands {
            SidebarCommands()
            ExecuteCommands()

            CommandMenu("Log") {
                Button(action: {
                    presentlogfile()
                }) {
                    Text("Show logfile")
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }
        }
        Settings {
            SidebarSettingsView(selectedprofile: $selectedprofile, reload: $reload)
                .environmentObject(rsyncUIData)
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

struct ContentView: View {
    @EnvironmentObject var rsyncversionObject: GetRsyncversion
    @EnvironmentObject var profilenames: Profilenames
    @EnvironmentObject var checkfornewversionofrsyncui: NewversionJSON

    @Binding var selectedprofile: String?
    @Binding var reload: Bool
    @State private var searchText = ""

    var body: some View {
        VStack {
            profilepicker

            ZStack {
                Sidebar(reload: $reload, selectedprofile: $selectedprofile)
                    .environmentObject(RsyncUIdata(profile: selectedprofile))
                    .environmentObject(errorhandling)
                    .environmentObject(InprogressCountExecuteOneTaskDetails())
                    .onChange(of: reload, perform: { _ in
                        reload = false
                    })
            }

            HStack {
                Label(rsyncversionObject.rsyncversion, systemImage: "swift")

                Spacer()

                if checkfornewversionofrsyncui.notifynewversion { notifynewversion }

                Spacer()

                Text(selectedprofile ?? NSLocalizedString("Default profile", comment: "default profile"))
            }
            .padding()
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                rsyncversionObject.update(SharedReference.shared.rsyncversion3)
            }
        }
        .searchable(text: $searchText)
    }

    var errorhandling: ErrorHandling {
        SharedReference.shared.errorobject = ErrorHandling()
        return SharedReference.shared.errorobject ?? ErrorHandling()
    }

    var profilepicker: some View {
        HStack {
            Picker(NSLocalizedString("Profile", comment: "default profile") + ":",
                   selection: $selectedprofile) {
                if let profiles = profilenames.profiles {
                    ForEach(profiles, id: \.self) { profile in
                        Text(profile.profile ?? "")
                            .tag(profile.profile)
                    }
                }
            }
            .frame(width: 200)

            Spacer()
        }
    }

    var notifynewversion: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text(NSLocalizedString("New version", comment: "settings"))
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 200, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
        .onAppear(perform: {
            // Show updated for 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                checkfornewversionofrsyncui.notifynewversion = false
            }
        })
    }
}
