import SwiftUI

struct ExternalExecutionCompletionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var executions: [RecentLoggedExecution] = []
    @State private var isLoading = true
    @State private var secondsRemaining = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("External execution completed")
                .font(.title2)
            Text("Latest logged executions across all profiles")
                .foregroundStyle(.secondary)

            Table(executions) {
                TableColumn("Date") { execution in
                    Text(execution.log.date.localized_string_from_date())
                }
                TableColumn("Profile", value: \.profile)
                TableColumn("Task") { execution in
                    Text(execution.hiddenID.formatted())
                }
                TableColumn("Result") { execution in
                    Text(execution.log.resultExecuted ?? "")
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                } else if executions.isEmpty {
                    Text("No logged executions")
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Text("RsyncUI will close in \(secondsRemaining) seconds.")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 850, height: 420)
        .interactiveDismissDisabled()
        .task {
            executions = await LogStoreService.latestExecutions()
            isLoading = false
        }
        .task {
            do {
                for remaining in (0..<10).reversed() {
                    try await Task.sleep(for: .seconds(1))
                    secondsRemaining = remaining
                }
                dismiss()
            } catch {
                // Dismissing the sheet cancels its countdown.
            }
        }
    }
}

struct RecentLoggedExecution: Identifiable {
    var id: UUID { log.id }
    let profile: String
    let hiddenID: Int
    let log: Log
}
