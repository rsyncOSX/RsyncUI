import SwiftUI
import UniformTypeIdentifiers

struct RestoreControlsView: View {
    @Binding var restore: ObservableRestore
    @State private var choosingDestination = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Toggle("Restore everything", isOn: Binding(
                    get: { restore.filestorestore == "./." },
                    set: { restore.filestorestore = $0 ? "./." : "" }
                ))
                Spacer()
                Toggle("Preview only (no files changed)", isOn: $restore.dryrun)
                    .toggleStyle(.switch)
            }

            if restore.filestorestore != "./." {
                LabeledContent("Selected item") {
                    Text(restore.filestorestore.isEmpty ? "Select an item in the file list" : restore.filestorestore)
                        .textSelection(.enabled)
                }
            }

            HStack {
                TextField("Destination folder", text: $restore.pathforrestore)
                    .textFieldStyle(.roundedBorder)
                Button("Choose Folder…") { choosingDestination = true }
            }
            .fileImporter(isPresented: $choosingDestination, allowedContentTypes: [.folder]) { result in
                switch result {
                case let .success(url):
                    restore.pathforrestore = url.path
                case let .failure(error):
                    restore.propagateError(error: error)
                }
            }
            .onAppear {
                if restore.pathforrestore.isEmpty, let path = SharedReference.shared.pathforrestore {
                    restore.pathforrestore = path
                }
            }
            .onChange(of: restore.pathforrestore) {
                SharedReference.shared.pathforrestore = try? ObservableRestore.validatedDestination(restore.pathforrestore)
            }

            if !restore.pathforrestore.isEmpty, !restore.verifyPathForRestore(restore.pathforrestore) {
                Label("Choose an existing, writable folder.", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            }

            if restore.selectedconfig != nil {
                Text(restore.restoreSummary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 8)
    }
}
