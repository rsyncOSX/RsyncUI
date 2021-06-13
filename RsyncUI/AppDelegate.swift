//
//  AppDelegate.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 12/01/2021.
//

import Cocoa
import SwiftUI
import UserNotifications

// @main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_: Notification) {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        center.requestAuthorization(options: options) { granted, _ in
            if granted {
                // application.registerForRemoteNotifications()
            }
        }
        // Create base profile catalog
        CatalogProfile().createrootprofilecatalog()
        ReadUserConfigurationPLIST()
        Running()
        // Create the window and set the content view.
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 950, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView:
            RsyncUIView()
                .environmentObject(RsyncOSXViewGetRsyncversion())
                .environmentObject(Profilenames())
                .environmentObject(shortcutactions))
        window.makeKeyAndOrderFront(nil)
        window.title = "RsyncUI"
        window.isMovableByWindowBackground = true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_: Notification) {
        // Insert code here to tear down your application
    }

    var shortcutactions: ShortcutActions {
        SharedReference.shared.shortcutobject = ShortcutActions()
        return SharedReference.shared.shortcutobject ?? ShortcutActions()
    }
}

extension AppDelegate {
    @IBAction func AboutPanel(_ sender: Any?) {
        let content = NSViewController()
        content.title = NSLocalizedString("About", comment: "about")
        let view = NSHostingView(rootView: AboutView())
        view.frame.size = view.fittingSize
        content.view = view
        let panel = NSPanel(contentViewController: content)
        panel.styleMask = [.closable, .titled]
        panel.orderFront(sender)
        panel.makeKey()
    }

    @IBAction func showPreferences(_ sender: Any?) {
        let content = NSViewController()
        content.title = NSLocalizedString("RsyncUI settings", comment: "settings")
        let view = NSHostingView(rootView: Usersettings()
            .environmentObject(SharedReference.shared.errorobject!)
            .environmentObject(RsyncOSXViewGetRsyncversion()))
        view.frame.size = view.fittingSize
        content.view = view
        let panel = NSPanel(contentViewController: content)
        panel.styleMask = [.closable, .titled, .resizable]
        panel.orderFront(sender)
        panel.makeKey()
    }

    @IBAction func logview(_ sender: Any?) {
        let content = NSViewController()
        content.title = NSLocalizedString("RsyncUI logfile", comment: "settings")
        let view = NSHostingView(rootView: LogfileView())
        view.frame.size = view.fittingSize
        content.view = view
        let panel = NSPanel(contentViewController: content)
        panel.styleMask = [.closable, .titled, .resizable]
        panel.orderFront(sender)
        panel.makeKey()
    }

    @IBAction func executeselected(_: Any?) {
        if SharedReference.shared.shortcutobject?.multipletaskviewisactive ?? false {
            SharedReference.shared.shortcutobject?.executemultipletasks = true
        }
        if SharedReference.shared.shortcutobject?.singetaskviewisactive ?? false {
            SharedReference.shared.shortcutobject?.executesingletask = true
        }
    }

    @IBAction func estimateselected(_: Any?) {
        if SharedReference.shared.shortcutobject?.multipletaskviewisactive ?? false {
            SharedReference.shared.shortcutobject?.estimatemultipletasks = true
        }
        if SharedReference.shared.shortcutobject?.singetaskviewisactive ?? false {
            SharedReference.shared.shortcutobject?.estimatesingletask = true
        }
    }

    @IBAction func schedules(_: Any?) {
        let running = Running()
        guard running.informifisrsyncshedulerunning() == false else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: (SharedReference.shared.pathrsyncschedule ?? "/Applications/")
                + SharedReference.shared.namersyncschedule))
        NSApp.terminate(self)
    }
}

@main
struct RsyncUIApp: App {
    @State private var selectedprofile: String?
    @State private var reload: Bool = false
    @StateObject var rsyncUIData = RsyncUIdata(profile: nil)
    @StateObject var rsyncOSXViewGetRsyncversion = RsyncOSXViewGetRsyncversion()
    @StateObject var profilenames = Profilenames()

    var body: some Scene {
        WindowGroup {
            ContentView(selectedprofile: $selectedprofile, reload: $reload)
                .environmentObject(rsyncUIData)
                .environmentObject(rsyncOSXViewGetRsyncversion)
                .environmentObject(profilenames)
        }
        .commands {
            SidebarCommands()
            ImportFromDevicesCommands()
        }
        Settings {
            SidebarSettingsView(selectedprofile: $selectedprofile, reload: $reload)
                .environmentObject(rsyncUIData)
                .environmentObject(rsyncOSXViewGetRsyncversion)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var rsyncversionObject: RsyncOSXViewGetRsyncversion
    @EnvironmentObject var profilenames: Profilenames

    @Binding var selectedprofile: String?
    @Binding var reload: Bool
    @StateObject private var new = NewversionJSON()

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

                if new.notifynewversion { notifynewversion }

                Spacer()

                Text(selectedprofile ?? NSLocalizedString("Default profile", comment: "default profile"))
            }
            .padding()
        }
        .padding()
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
                new.notifynewversion = false
            }
        })
    }
}
