import OSLog
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_: Notification) {
        GlobalTimer.shared.invalidateAllSchedulesAndTimer()
    }
}

@main
struct RsyncUIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showabout: Bool = false

    var body: some Scene {
        Window("RsyncUI", id: "main") {
            RsyncUIView()
                .task {
                    Homepath().createRootProfileCatalog()
                }
                .frame(minWidth: 1100, idealWidth: 1300, minHeight: 580)
                .sheet(isPresented: $showabout) { AboutView() }
                .onDisappear {
                    // Quit the app when the main window is closed
                    performCleanupTask()
                    NSApplication.shared.terminate(nil)
                }
        }
        .commands {
            SidebarCommands()
            ImportExportCommands()
            ExecuteCommands()
            SnapshotCommands()

            CommandGroup(replacing: .help) {
                ConditionalGlassButton(
                    systemImage: "questionmark.text.page.fill",
                    text: "RsyncUI documentation",
                    helpText: "RsyncUI documentation"
                ) {
                    let documents = "https://rsyncui.netlify.app/docs/"
                    if let url = URL(string: documents) {
                        NSWorkspace.shared.open(url)
                    }
                }
            }

            CommandGroup(replacing: .appInfo) {
                ConditionalGlassButton(
                    systemImage: "",
                    text: "About RsyncUI",
                    helpText: "About"
                ) {
                    showabout = true
                }
            }
        }

        Window("RsyncUI log", id: "rsyncuilog") {
            LogfileView()
        }
        .defaultPosition(.center)
        .defaultSize(width: 600, height: 400)

        Settings {
            SidebarSettingsView()
        }
    }

    private func performCleanupTask() {
        Logger.process.debugMessageOnly("RsyncUIApp: performCleanupTask(), RsyncUI shutting down, doing clean up")
        GlobalTimer.shared.invalidateAllSchedulesAndTimer()
        SharedReference.shared.checkeandterminateprocess()
    }
}

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier
    static let process = Logger(subsystem: subsystem ?? "process", category: "process")

    func errorMessageOnly(_ message: String) {
        #if DEBUG
            error("\(message)")
        #endif
    }

    func debugMessageOnly(_ message: String) {
        #if DEBUG
            debug("\(message)")
        #endif
    }

    func debugThreadOnly(_ message: String) {
        #if DEBUG
            if Thread.checkIsMainThread() {
                debug("\(message) Running on main thread")
            } else {
                debug("\(message) NOT on main thread, currently on \(Thread.current)")
            }
        #endif
    }
}
