//
//  ConfigurationsTableDataMainView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/04/2024.
//

import SwiftUI

struct ConfigurationsTableDataMainView: View {
    @Environment(\.colorScheme) var colorScheme

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
            TableColumn("%") { data in
                if data.hiddenID == progressdetails.hiddenIDatwork, max > 0, progress <= max {
                    HStack(spacing: 8) {
                        // Progress bar with percentage overlay
                        ZStack(alignment: .leading) {
                            ProgressView(value: progress, total: max)
                                .frame(width: 80)
                                .scaleEffect(y: 1.5, anchor: .center)

                            Text("\(Int((progress / max) * 100))%")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .width(min: 100, max: 150)
            .defaultVisibility(visibleProgress)

            TableColumn("Num") { data in
                if data.hiddenID == progressdetails.hiddenIDatwork, max > 0, progress <= max {
                    HStack(spacing: 8) {
                        // Compact ratio display
                        HStack(spacing: 4) {
                            Text("\(Int(progress))")
                                .contentTransition(.numericText(countsDown: false))
                                .animation(.default, value: progress)

                            Text("/")
                                .foregroundStyle(.secondary)

                            Text("\(Int(max))")
                                .foregroundStyle(.secondary)
                        }
                        .font(.system(.body, design: .monospaced))
                    }
                    .padding(.vertical, 4)
                }
            }
            .width(min: 150, max: 250)
            .defaultVisibility(visibleProgress)

            TableColumn("Synchronize ID") { data in
                if let index = progressdetails.estimatedlist?.firstIndex(where: { $0.id == data.id }) {
                    if progressdetails.estimatedlist?[index].datatosynchronize == false,
                       progressdetails.estimatedlist?[index].preparedoutputfromrsync?.count ?? 0 >
                       SharedReference.shared.alerttagginglines {
                        // If tagging is kind of suspicious and need attention

                        if data.backupID.isEmpty == true {
                            Text("Synchronize ID")
                                .foregroundColor(.yellow)

                        } else {
                            Text(data.backupID)
                                .foregroundColor(.yellow)
                        }

                        Text(rsyncUIdata.profile ?? "Default")
                            .foregroundColor(.yellow)
                    } else {
                        let color: Color = progressdetails.estimatedlist?[index].datatosynchronize == true ? .blue : .red
                        if data.backupID.isEmpty == true {
                            Text("Synchronize ID")
                                .foregroundColor(color)

                        } else {
                            Text(data.backupID)
                                .foregroundColor(color)
                        }
                    }
                } else {
                    if data.backupID.isEmpty == true {
                        Text("Synchronize ID")

                    } else {
                        Text(data.backupID)
                    }
                }
            }
            .width(min: 50, max: 150)
            TableColumn("Action") { data in
                if data.task == SharedReference.shared.halted {
                    Image(systemName: "stop.fill")
                        .foregroundColor(Color(.red))
                        .contextMenu {
                            ConditionalGlassButton(
                                systemImage: "stop.fill",
                                text: "Toggle halt task",
                                helpText: "Enable task"
                            ) {
                                let index = getIndex(selecteduuids)
                                guard index != -1 else { return }
                                updateHalted(index)
                            }
                        }
                } else {
                    Text(data.task)
                        .contextMenu {
                            ConditionalGlassButton(
                                systemImage: "stop.fill",
                                text: "Toggle halt task",
                                helpText: "Halt task"
                            ) {
                                let index = getIndex(selecteduuids)
                                guard index != -1 else { return }
                                updateHalted(index)
                            }
                        }
                }
            }
            .width(max: 80)
            TableColumn("Source folder", value: \.localCatalog)
                .width(min: 120, max: 300)
            TableColumn("Destination folder", value: \.offsiteCatalog)
                .width(min: 120, max: 300)
            TableColumn("Server") { data in
                if data.offsiteServer.count > 0 {
                    Text(data.offsiteServer)
                } else {
                    Text("localhost")
                }
            }
            .width(min: 50, max: 90)
            TableColumn("Min/hour/day") { data in
                var seconds: Double {
                    if let date = data.dateRun {
                        let lastbackup = date.en_date_from_string()
                        return lastbackup.timeIntervalSinceNow * -1
                    } else {
                        return 0
                    }
                }
                let color: Color = markConfig(seconds) == true ? .red : (colorScheme == .dark ? .white : .black)

                Text(seconds.latest())
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                    .foregroundColor(color)
            }
            .width(max: 90)

            TableColumn("Date last") { data in
                Text(data.dateRun ?? "")
            }
            .width(max: 120)
        }
    }

    var configurations: [SynchronizeConfiguration] {
        rsyncUIdata.configurations ?? []
    }

    var visibleProgress: Visibility {
        if max == 0 {
            .hidden
        } else {
            .visible
        }
    }

    private func markConfig(_ seconds: Double) -> Bool {
        seconds / (60 * 60 * 24) > Double(SharedReference.shared.marknumberofdayssince)
    }

    private func getIndex(_: Set<UUID>) -> Int {
        if let configurations = rsyncUIdata.configurations {
            if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                index
            } else {
                -1
            }
        } else {
            -1
        }
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
            WriteSynchronizeConfigurationJSON(rsyncUIdata.profile, rsyncUIdata.configurations)
            selecteduuids.removeAll()
        }
    }
}
