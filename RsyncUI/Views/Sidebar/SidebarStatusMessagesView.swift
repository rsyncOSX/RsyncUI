import SwiftUI

struct SidebarStatusMessagesView: View {
    let newVersionAvailable: Bool
    @Binding var mountingVolumeNow: Bool
    let rsyncVersionShort: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if newVersionAvailable {
                Label("Update available", systemImage: "arrow.down.circle")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }

            if mountingVolumeNow {
                Label("Mounting volume...", systemImage: "externaldrive")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .onAppear {
                        Task {
                            try? await Task.sleep(seconds: 2)
                            mountingVolumeNow = false
                        }
                    }
            }

            Text(rsyncVersionShort)
                .font(.caption2)
                .foregroundStyle(.secondary).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
