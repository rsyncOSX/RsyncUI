//
//  ConfigurationsTableDataMainView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/04/2024.
//

import SwiftUI

struct ConfigurationsTableDataMainView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var filterstring: String
    @Binding var progress: Double

    let progressdetails: ProgressDetails
    let max: Double

    var body: some View {
        Table(configurations.filter {
            filterstring.isEmpty ? true : $0.backupID.contains(filterstring)
        }, selection: $selecteduuids) {
            TableColumn("") { data in
                if data.hiddenID == progressdetails.hiddenIDatwork, max > 0, progress <= max {
                    ProgressView(value: progress, total: max)
                        .frame(width: 30)
                        .scaleEffect(y: 1.5, anchor: .center)
                } else {
                    Circle()
                        .fill(statusColor(for: data))
                        .frame(width: 8, height: 8)
                }
            }
            .width(min: 30, max: 36)

            TableColumn("Synchronize ID") { data in
                HStack(spacing: 4) {
                    synchronizeIDText(for: data)

                    ConfigurationTaskBadge(task: data.task)
                }
                .opacity(opacity(for: data))
                .contextMenu {
                    AdaptiveProminentButton(
                        systemImage: "stop.fill",
                        text: "Toggle halt task",
                        helpText: data.task == SharedReference.shared.halted ? "Enable task" : "Halt task"
                    ) {
                        if let index = getIndex(data.id) {
                            updateHalted(index)
                        }
                    }
                }
            }
            .width(min: 80, max: 200)

            TableColumn("Source") { data in
                Text(data.localCatalog)
                    .opacity(opacity(for: data))
            }
            .width(min: 120, max: 300)

            TableColumn("Destination") { data in
                Text(data.offsiteCatalog)
                    .opacity(opacity(for: data))
            }
            .width(min: 120, max: 300)

            TableColumn("Server") { data in
                Group {
                    if data.offsiteServer.count > 0 {
                        Text(data.offsiteServer)
                    } else {
                        Text("localhost")
                    }
                }
                .opacity(opacity(for: data))
            }
            .width(min: 50, max: 100)

            TableColumn("Last Sync") { data in
                if data.hiddenID == progressdetails.hiddenIDatwork, max > 0, progress <= max {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int((progress / max) * 100))%")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.blue)
                            .contentTransition(.numericText(countsDown: false))
                            .animation(.default, value: progress)
                        Text("syncing...")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                } else if data.task == SharedReference.shared.halted {
                    Text("halted")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                } else if let dateRun = data.dateRun {
                    let lastbackup = dateRun.en_date_from_string()
                    let seconds = lastbackup.timeIntervalSinceNow * -1
                    let isStale = markConfig(seconds)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(seconds.latest())
                            .font(.caption)
                            .foregroundStyle(isStale ? .red : .primary)
                        Text(dateRun)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                } else {
                    Text("never")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .width(min: 80, max: 130)
        }
    }

    var configurations: [SynchronizeConfiguration] {
        rsyncUIdata.configurations ?? []
    }

    @ViewBuilder
    private func synchronizeIDText(for data: SynchronizeConfiguration) -> some View {
        if let index = progressdetails.estimatedlist?.firstIndex(where: { $0.id == data.id }) {
            if progressdetails.estimatedlist?[index].datatosynchronize == false,
               progressdetails.estimatedlist?[index].preparedoutputfromrsync?.count ?? 0 >
               SharedReference.shared.alerttagginglines {
                // If tagging is kind of suspicious and need attention
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.backupID.isEmpty ? "No ID set" : data.backupID)
                    Text(rsyncUIdata.profile ?? "Default")
                        .font(.caption2)
                }
                .foregroundStyle(.yellow)
            } else {
                let color: Color = progressdetails.estimatedlist?[index].datatosynchronize == true ? .blue : .red
                Text(data.backupID.isEmpty ? "No ID set" : data.backupID)
                    .foregroundStyle(color)
            }
        } else {
            Text(data.backupID.isEmpty ? "No ID set" : data.backupID)
        }
    }

    private func statusColor(for data: SynchronizeConfiguration) -> Color {
        if data.task == SharedReference.shared.halted {
            return .gray
        }
        guard let dateRun = data.dateRun else {
            return .orange
        }
        let lastbackup = dateRun.en_date_from_string()
        let daysSince = lastbackup.timeIntervalSinceNow * -1 / (60 * 60 * 24)
        if daysSince > Double(SharedReference.shared.marknumberofdayssince) {
            return .orange
        }
        return .green
    }

    private func opacity(for data: SynchronizeConfiguration) -> Double {
        data.task == SharedReference.shared.halted ? 0.4 : 1
    }

    private func markConfig(_ seconds: Double) -> Bool {
        seconds / (60 * 60 * 24) > Double(SharedReference.shared.marknumberofdayssince)
    }

    private func getIndex(_ id: SynchronizeConfiguration.ID) -> Int? {
        if let configurations = rsyncUIdata.configurations {
            if let index = configurations.firstIndex(where: { $0.id == id }) {
                return index
            }
        }
        return nil
    }

    private func updateHalted(_ index: Int) {
        if let halted = rsyncUIdata.configurations?[index].halted,
           let task = rsyncUIdata.configurations?[index].task {
            if halted == 0 {
                // Halt task
                switch task {
                case SharedReference.shared.synchronize:
                    rsyncUIdata.configurations?[index].halted = 1
                    rsyncUIdata.configurations?[index].task = SharedReference.shared.halted
                case SharedReference.shared.syncremote:
                    rsyncUIdata.configurations?[index].halted = 2
                    rsyncUIdata.configurations?[index].task = SharedReference.shared.halted
                case SharedReference.shared.snapshot:
                    rsyncUIdata.configurations?[index].halted = 3
                    rsyncUIdata.configurations?[index].task = SharedReference.shared.halted
                default:
                    break
                }
            } else {
                // Enable task
                switch halted {
                case 1:
                    rsyncUIdata.configurations?[index].task = SharedReference.shared.synchronize
                    rsyncUIdata.configurations?[index].halted = 0
                case 2:
                    rsyncUIdata.configurations?[index].task = SharedReference.shared.syncremote
                    rsyncUIdata.configurations?[index].halted = 0
                case 3:
                    rsyncUIdata.configurations?[index].task = SharedReference.shared.snapshot
                    rsyncUIdata.configurations?[index].halted = 0
                default:
                    break
                }
            }
            let profile = rsyncUIdata.profile
            let configurations = rsyncUIdata.configurations
            Task { @MainActor in
                await WriteSynchronizeConfigurationJSON.write(profile, configurations)
                selecteduuids.removeAll()
            }
        }
    }
}

@MainActor
struct ConfigurationTaskBadge: View {
    let task: String

    var body: some View {
        if task == SharedReference.shared.halted {
            Label("halted", systemImage: "stop.fill")
                .font(.caption2)
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.red.opacity(0.15))
                .foregroundStyle(.red)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        } else if task.isEmpty == false {
            Text(task)
                .font(.caption2)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(color.opacity(0.15))
                .foregroundStyle(color)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
    }

    private var color: Color {
        switch task {
        case SharedReference.shared.synchronize:
            .green
        case SharedReference.shared.snapshot:
            .orange
        case SharedReference.shared.syncremote:
            .blue
        default:
            .secondary
        }
    }
}
