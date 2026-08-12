import SwiftUI

struct SummarizedDetailsContentView: View {
    @Bindable var progressdetails: ProgressDetails
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var executetaskpath: [Tasks]
    @Binding var isPresentingConfirm: Bool

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
                            if datatosynchronize.count == 0,
                               SharedReference.shared.alwaysshowestimateddetailsview == false {
                                executetaskpath.removeAll()
                            }
                        }
                    }
            } else {
                HStack(spacing: 0) {
                    leftcolumndetails

                    SummaryTablesActionDivider(
                        showsSynchronizeButton: datatosynchronize,
                        progressdetails: progressdetails,
                        executetaskpath: $executetaskpath,
                        isPresentingConfirm: $isPresentingConfirm
                    )

                    rightcolumndetails
                }
            }
        }
        .toolbar(content: {
            if datatosynchronizeURL {
                ToolbarItem {
                    TimerView(executetaskpath: $executetaskpath)
                }

                ToolbarItem {
                    Spacer()
                }
            }
        })
        .frame(maxWidth: .infinity)
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

    private var leftcolumndetails: some View {
        Table(progressdetails.estimatedlist ?? [],
              selection: $selecteduuids) {
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

                    ConfigurationTaskBadge(task: data.task)
                }
            }
            .width(min: 80, max: 120)
            TableColumn("Source", value: \.localCatalog)
                .width(min: 100, max: 250)
            TableColumn("Server") { data in
                if data.offsiteServer.count > 0 {
                    Text(data.offsiteServer)
                } else {
                    Text("localhost")
                }
            }
            .width(max: 100)
        }
        .frame(minWidth: 330, maxWidth: 530)
        .onAppear {
            if selecteduuids.count > 0 {
                // Reset preselected tasks, must do a few seconds timout
                // before clearing it out
                Task {
                    try? await Task.sleep(seconds: 2)
                    selecteduuids.removeAll()
                }
            }
        }
    }

    private var rightcolumndetails: some View {
        Table(progressdetails.estimatedlist ?? [],
              selection: $selecteduuids) {
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
            .width(max: 40)
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
            .width(max: 40)
            TableColumn("Updates") { files in
                if files.datatosynchronize {
                    Text(files.filestransferred)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundStyle(.blue)
                } else {
                    Text(files.filestransferred)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .width(max: 55)
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
            .width(max: 100)
            TableColumn("Total files") { files in
                Text(files.numberoffiles)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(max: 90)
            TableColumn("Total kB") { files in
                Text("\(files.totalfilesizeInt / 1000)")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(max: 80)
            TableColumn("Total catalogs") { files in
                Text(files.totaldirectories)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(max: 70)
        }
        .onChange(of: selecteduuids) {
            guard selecteduuids.count > 0 else { return }
            executetaskpath.append(Tasks(task: .dryrunonetaskalreadyestimated))
        }
    }
}

private struct SummaryTablesActionDivider: View {
    let showsSynchronizeButton: Bool
    @Bindable var progressdetails: ProgressDetails
    @Binding var executetaskpath: [Tasks]
    @Binding var isPresentingConfirm: Bool

    var body: some View {
        ZStack {
            Divider()

            if showsSynchronizeButton {
                synchronizeButton
            }
        }
        .frame(width: 1)
        .frame(maxHeight: .infinity)
        .zIndex(1)
    }

    @ViewBuilder
    private var synchronizeButton: some View {
        if SharedReference.shared.confirmexecute {
            if #available(macOS 26.0, *) {
                Button(action: requestExecution) {
                    Label("Synchronize", systemImage: "play.fill")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(RefinedGlassButtonStyle())
                .help("Synchronize")
                .confirmationDialog("Synchronize tasks?", isPresented: $isPresentingConfirm) {
                    Button("Synchronize", role: .destructive, action: execute)
                }
            } else {
                Button(action: requestExecution) {
                    Label("Synchronize", systemImage: "play.fill")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .imageScale(.large)
                }
                .buttonStyle(.borderedProminent)
                .help("Synchronize")
                .confirmationDialog("Synchronize tasks?", isPresented: $isPresentingConfirm) {
                    Button("Synchronize", role: .destructive, action: execute)
                }
            }
        } else {
            ConditionalGlassButton(
                systemImage: "play.fill",
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
