import SwiftUI

struct RestoreControlsView: View {
    @Binding var restore: ObservableRestore

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                EditValueScheme(
                    500,
                    "Select files to restore or \"./.\" for full restore",
                    $restore.filestorestore
                )

                EditValueErrorScheme(
                    500,
                    "Path for restore",
                    $restore.pathforrestore,
                    restore.verifyPathForRestore(restore.pathforrestore)
                )
                .foregroundStyle(restore.verifyPathForRestore(restore.pathforrestore) ? Color.white : Color.red)
                .onAppear {
                    if let pathforrestore = SharedReference.shared.pathforrestore {
                        restore.pathforrestore = pathforrestore
                    }
                }
                .onChange(of: restore.pathforrestore) {
                    guard restore.verifyPathForRestore(restore.pathforrestore) else {
                        return
                    }
                    if restore.pathforrestore.hasSuffix("/") == false {
                        restore.pathforrestore.append("/")
                    }
                    SharedReference.shared.pathforrestore = restore.pathforrestore
                }
            }

            Spacer()

            Toggle("--dry-run", isOn: $restore.dryrun)
                .toggleStyle(.switch)
                .animation(.easeInOut(duration: 0.35), value: restore.dryrun)
        }
    }
}
