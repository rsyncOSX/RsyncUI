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
                ConditionalGlassButton(
                    systemImage: "questionmark.text.page.fill",
                    text: "RsyncUI documentation",
                    helpText: "RsyncUI documentation"
                ) {
                    let documents = "https://rsyncui.netlify.app/docs/"
                    NSWorkspace.shared.open(URL(string: documents)!)
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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                performCleanupTask()
            }
        }

        // Add a new WindowGroup for your floating window
        Window("Details", id: "floating-details") {
            AllOutputView()
                .frame(minWidth: 400, minHeight: 300)
        }
        .defaultPosition(.center)
        .defaultSize(width: 600, height: 400)

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
