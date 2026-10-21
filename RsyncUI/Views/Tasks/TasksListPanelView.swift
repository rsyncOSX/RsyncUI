import SwiftUI

struct TasksListPanelView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var doubleclick: Bool
    @Binding var progress: Double

    let progressdetails: ProgressDetails
    let max: Double
    let onSelectedUuidsChange: () -> Void
    let onEstimatedListChange: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SynchronizeTasksHeading(
                profile: rsyncUIdata.profile ?? "Default",
                taskCount: rsyncUIdata.configurations?.count ?? 0,
                selectionCount: selecteduuids.count
            )

            ListofTasksMainView(
                rsyncUIdata: rsyncUIdata,
                selecteduuids: $selecteduuids,
                doubleclick: $doubleclick,
                progress: $progress,
                progressdetails: progressdetails,
                max: max
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if selecteduuids.count == 1,
               let configuration = rsyncUIdata.configurations?.first(where: { selecteduuids.contains($0.id) }) {
                Divider()
                SelectedTaskRouteView(configuration: configuration)
            }

            Divider()
            SynchronizeSelectionFooter(selectionCount: selecteduuids.count)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: selecteduuids) {
            onSelectedUuidsChange()
        }
        .onChange(of: progressdetails.estimatedlist) {
            onEstimatedListChange()
        }
    }
}

private struct SynchronizeTasksHeading: View {
    let profile: String
    let taskCount: Int
    let selectionCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Synchronize")
                .font(.title2.weight(.semibold))
            Text("\(profile) profile · \(taskCount) tasks · \(selectionCount) selected")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

private struct SelectedTaskRouteView: View {
    let configuration: SynchronizeConfiguration

    // A remote pull reverses the local and offsite paths. Halted tasks retain
    // their original mode in `halted` (2 is a remote pull).
    private var isRemotePull: Bool {
        configuration.task == SharedReference.shared.syncremote ||
            (configuration.task == SharedReference.shared.halted && configuration.halted == 2)
    }

    private var remoteEndpoint: String {
        if configuration.offsiteServer.isEmpty { return String(localized: "This Mac") }
        if configuration.offsiteUsername.isEmpty { return configuration.offsiteServer }
        return "\(configuration.offsiteUsername)@\(configuration.offsiteServer)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(configuration.backupID.isEmpty ? String(localized: "Unnamed task") : configuration.backupID)
                    .font(.headline)
                ConfigurationTaskBadge(task: configuration.task)
            }
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 20) {
                    TaskEndpointView(
                        title: "Source",
                        host: isRemotePull ? remoteEndpoint : String(localized: "This Mac"),
                        path: isRemotePull ? configuration.offsiteCatalog : configuration.localCatalog
                    )
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    TaskEndpointView(
                        title: "Destination",
                        host: isRemotePull ? String(localized: "This Mac") : remoteEndpoint,
                        path: isRemotePull ? configuration.localCatalog : configuration.offsiteCatalog
                    )
                }
                VStack(alignment: .leading, spacing: 12) {
                    TaskEndpointView(
                        title: "Source",
                        host: isRemotePull ? remoteEndpoint : String(localized: "This Mac"),
                        path: isRemotePull ? configuration.offsiteCatalog : configuration.localCatalog
                    )
                    TaskEndpointView(
                        title: "Destination",
                        host: isRemotePull ? String(localized: "This Mac") : remoteEndpoint,
                        path: isRemotePull ? configuration.localCatalog : configuration.offsiteCatalog
                    )
                }
            }
        }
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.background)
    }
}

private struct TaskEndpointView: View {
    let title: LocalizedStringKey
    let host: String
    let path: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(host)
                .font(.subheadline.weight(.medium))
            Text(path)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct SynchronizeSelectionFooter: View {
    let selectionCount: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .accessibilityHidden(true)
            if selectionCount == 0 {
                Text("No selection · Actions apply to all enabled tasks")
            } else {
                Text("\(selectionCount) selected · Estimate to preview changes")
            }
            Spacer(minLength: 0)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}
