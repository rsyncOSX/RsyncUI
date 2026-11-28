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
            TaskWorkspaceHeading(
                title: "Synchronize",
                systemImage: "arrow.triangle.2.circlepath",
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

struct TaskWorkspaceHeading: View {
    let title: LocalizedStringKey
    let systemImage: String
    let profile: String
    let taskCount: Int
    let selectionCount: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2.weight(.medium))
                .foregroundStyle(.tint)
                .frame(width: 40, height: 40)
                .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Text("\(profile) profile · \(taskCount) tasks · \(selectionCount) selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct SelectedTaskRouteView: View {
    let configuration: SynchronizeConfiguration

    private var remoteEndpoint: String {
        if configuration.offsiteServer.isEmpty {
            return String(localized: "This Mac")
        }
        if configuration.offsiteUsername.isEmpty {
            return configuration.offsiteServer
        }
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
                        host: configuration.displaysRemoteSource ? remoteEndpoint : String(localized: "This Mac"),
                        path: configuration.displaySourcePath
                    )
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    TaskEndpointView(
                        title: "Destination",
                        host: configuration.displaysRemoteSource ? String(localized: "This Mac") : remoteEndpoint,
                        path: configuration.displayDestinationPath
                    )
                }
                VStack(alignment: .leading, spacing: 12) {
                    TaskEndpointView(
                        title: "Source",
                        host: configuration.displaysRemoteSource ? remoteEndpoint : String(localized: "This Mac"),
                        path: configuration.displaySourcePath
                    )
                    TaskEndpointView(
                        title: "Destination",
                        host: configuration.displaysRemoteSource ? String(localized: "This Mac") : remoteEndpoint,
                        path: configuration.displayDestinationPath
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(verbatim: "\(host), \(path)"))
    }
}
