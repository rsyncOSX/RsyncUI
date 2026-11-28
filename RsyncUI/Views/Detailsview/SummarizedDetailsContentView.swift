import SwiftUI

struct SummarizedDetailsContentView: View {
    @Bindable var progressdetails: ProgressDetails
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var executetaskpath: [Tasks]
    @Binding var isPresentingConfirm: Bool

    @State private var showIncompletePreview = false
    @State private var detailSelection = Set<UUID>()
    @State private var runCommand = false
    let previewScope: Set<UUID>
    let configurations: [SynchronizeConfiguration]
    let profile: String?
    let queryitem: URLQueryItem?

    var body: some View {
        HStack {
            if progressdetails.estimatealltasksinprogress {
                EstimationInProgressView(progressdetails: progressdetails,
                                         selecteduuids: $selecteduuids,
                                         profile: profile,
                                         configurations: configurations)
                    .onDisappear {
                        let datatosynchronize = progressdetails.estimatedlist?.compactMap { element in
                            element.datatosynchronize ? true : nil
                        }
                        if let datatosynchronize {
                            if datatosynchronize.count == 0, !incomplete,
                               SharedReference.shared.alwaysshowestimateddetailsview == false {
                                executetaskpath.removeAll()
                            }
                        }
                    }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    PreflightOverview(estimates: progressdetails.estimatedlist ?? [], incomplete: incomplete)
                    Divider()
                    changeDetails
                    if incomplete {
                        Button("Review Incomplete Estimate…") { showIncompletePreview = true }
                            .padding()
                    } else if datatosynchronize {
                        Divider()
                        PreflightActionBar(
                            progressdetails: progressdetails,
                            executetaskpath: $executetaskpath,
                            isPresentingConfirm: $isPresentingConfirm
                        )
                    }
                }
            }
        }
        .toolbar(content: {
            if datatosynchronizeURL && !incomplete {
                ToolbarItem {
                    TimerView(executetaskpath: $executetaskpath)
                }

                ToolbarItem {
                    Spacer()
                }
            }
        })
        .focusedSceneValue(\.startexecution, $runCommand)
        .onChange(of: runCommand) {
            guard runCommand else { return }
            runCommand = false
            guard !progressdetails.estimatealltasksinprogress, !previewScope.isEmpty else { return }
            if incomplete {
                showIncompletePreview = true
            } else if datatosynchronize {
                if SharedReference.shared.confirmexecute && progressdetails.confirmExecuteTasks() {
                    isPresentingConfirm = true
                } else {
                    executetaskpath = [Tasks(task: .executestimatedview)]
                }
            }
        }
        .sheet(isPresented: $showIncompletePreview) {
            SynchronizeConfirmationView(
                configurations: configurations.filter { previewScope.contains($0.id) },
                incompletePreview: true,
                estimatedIDs: estimatedRunScope,
                cancel: { showIncompletePreview = false },
                preview: {
                    showIncompletePreview = false
                    selecteduuids = previewScope
                    progressdetails.resetCounts()
                    progressdetails.startEstimation()
                },
                synchronize: {
                    showIncompletePreview = false
                    selecteduuids = previewScope
                    executetaskpath = [Tasks(task: .executenoestimatetasksview)]
                },
                synchronizeEstimated: {
                    showIncompletePreview = false
                    let scope = estimatedRunScope
                    guard !scope.isEmpty else { return }
                    selecteduuids = scope
                    executetaskpath = [Tasks(task: .executestimatedview)]
                }
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var estimatedRunScope: Set<UUID> {
        TasksView.estimatedRunScope(for: previewScope, estimates: progressdetails.estimatedlist ?? [])
    }

    private var incomplete: Bool {
        guard !previewScope.isEmpty, !progressdetails.estimatealltasksinprogress else { return false }
        let usable = (progressdetails.estimatedlist ?? []).filter(\.hasUsableStatistics)
        return !TasksView.hasPreview(for: previewScope, estimatedIDs: Set(usable.map(\.id)))
    }

    /// URL code
    private var datatosynchronizeURL: Bool {
        if queryitem != nil, progressdetails.estimatealltasksinprogress == false {
            let datatosynchronize = progressdetails.estimatedlist?.filter { $0.datatosynchronize == true }
            if (datatosynchronize?.count ?? 0) > 0 {
                return true
            } else {
                return false
            }
        }
        return false
    }

    private var datatosynchronize: Bool {
        if queryitem == nil, progressdetails.estimatealltasksinprogress == false {
            let datatosynchronize = progressdetails.estimatedlist?.filter { $0.datatosynchronize == true }
            if (datatosynchronize?.count ?? 0) > 0 {
                return true
            } else {
                return false
            }
        }
        return false
    }

    private var changeDetails: some View {
        Table(progressdetails.estimatedlist ?? [],
              selection: $detailSelection) {
            TableColumn("Synchronize ID") { data in
                HStack(spacing: 4) {
                    if data.datatosynchronize {
                        if data.backupID.isEmpty == true {
                            Text("No ID set")
                                .foregroundStyle(.blue)
                        } else {
                            Text(data.backupID)
                                .foregroundStyle(.blue)
                        }
                    } else {
                        if data.backupID.isEmpty == true {
                            Text("No ID set")
                        } else {
                            Text(data.backupID)
                        }
                    }

                    ConfigurationTaskBadge(task: data.task, hidesSynchronize: true)
                }
            }
            .width(min: 100, ideal: 105, max: 150)
            TableColumn("Local path") { data in
                Text(data.localCatalog)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(data.localCatalog)
            }
            .width(min: 88, ideal: 90, max: 300)
            TableColumn("Server") { data in
                if data.offsiteServer.count > 0 {
                    Text(data.offsiteServer)
                } else {
                    Text("localhost")
                }
            }
            .width(min: 60, ideal: 75, max: 100)
            TableColumn("New") { files in
                if files.datatosynchronize {
                    Text(files.newfiles)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundStyle(.blue)
                } else {
                    Text(files.newfiles)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .width(min: 30, ideal: 32, max: 40)
            TableColumn("Delete") { files in
                if files.datatosynchronize {
                    Text(files.deletefiles)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundStyle(.blue)
                } else {
                    Text(files.deletefiles)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .width(min: 40, ideal: 40, max: 45)
            TableColumn("Transferred") { files in
                if files.datatosynchronize {
                    Text(files.filestransferred)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundStyle(.blue)
                } else {
                    Text(files.filestransferred)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .width(min: 65, ideal: 70, max: 80)
            TableColumn("kB transferred") { files in
                if files.datatosynchronize {
                    Text("\(files.totaltransferredfilessizeInt / 1000)")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundStyle(.blue)
                } else {
                    Text("\(files.totaltransferredfilessizeInt / 1000)")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .width(min: 80, ideal: 88, max: 95)
            TableColumn("Total files") { files in
                Text(files.numberoffiles)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 60, ideal: 62, max: 75)
            TableColumn("Total kB") { files in
                Text("\(files.totalfilesizeInt / 1000)")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 65, ideal: 68, max: 80)
            TableColumn("Total catalogs") { files in
                Text(files.totaldirectories)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 80, ideal: 82, max: 95)
        }
        .onAppear {
            detailSelection.removeAll()
            selecteduuids.removeAll()
        }
        .onChange(of: detailSelection) {
            guard !detailSelection.isEmpty else { return }
            selecteduuids = detailSelection
            executetaskpath.append(Tasks(task: .dryrunonetaskalreadyestimated))
        }
    }
}

private struct PreflightActionBar: View {
    @Bindable var progressdetails: ProgressDetails
    @Binding var executetaskpath: [Tasks]
    @Binding var isPresentingConfirm: Bool

    var body: some View {
        HStack {
            Spacer()
            synchronizeButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }

    @ViewBuilder
    private var synchronizeButton: some View {
        if SharedReference.shared.confirmexecute {
            AdaptiveProminentButton(
                systemImage: "play.fill",
                text: "Synchronize",
                helpText: "Synchronize",
                action: requestExecution
            )
            .confirmationDialog("Synchronize tasks?", isPresented: $isPresentingConfirm) {
                Button("Synchronize", role: .destructive, action: execute)
            }
        } else {
            AdaptiveProminentButton(
                systemImage: "play.fill",
                text: "Synchronize",
                helpText: "Synchronize",
                action: execute
            )
        }
    }

    private func requestExecution() {
        isPresentingConfirm = progressdetails.confirmExecuteTasks()
        if isPresentingConfirm == false {
            execute()
        }
    }

    private func execute() {
        executetaskpath.removeAll()
        executetaskpath.append(Tasks(task: .executestimatedview))
    }
}

private struct PreflightOverview: View {
    let estimates: [RemoteDataNumbers]
    let incomplete: Bool

    private var deletedFiles: Int {
        estimates.reduce(0) { $0 + $1.deletefilesInt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estimate (Dry Run)")
                .font(.title2.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            if estimates.isEmpty {
                Text("No estimates available")
                    .foregroundStyle(.secondary)
            } else if incomplete {
                Text("Statistics are unavailable for one or more tasks.")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 145))], alignment: .leading) {
                    PreflightMetric(title: "Created", icon: "plus.square", color: .blue,
                                    value: estimates.reduce(0) { $0 + $1.newfilesInt }.formatted())
                    PreflightMetric(title: "Transferred", icon: "arrow.right.square", color: .orange,
                                    value: estimates.reduce(0) { $0 + $1.filestransferredInt }.formatted())
                    PreflightMetric(title: "Deleted", icon: "trash", color: deletedFiles > 0 ? .red : .secondary,
                                    value: deletedFiles.formatted())
                    PreflightMetric(title: "Transfer size", icon: "externaldrive", color: .secondary,
                                    value: estimates.reduce(Int64(0)) { $0 + Int64($1.totaltransferredfilessizeInt) }
                                        .formatted(.byteCount(style: .file)))
                }
            }
        }
        .padding(20)
    }
}

private struct PreflightMetric: View {
    let title: LocalizedStringKey
    let icon: String
    let color: Color
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}
