//
//  TasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import Observation
import OSLog
import SwiftUI

enum SheetType: Identifiable {
    case importview
    case exportview

    var id: Int {
        hashValue
    }
}

struct CopyItem: Identifiable, Codable, Transferable {
    let id: UUID
    let task: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}

struct TasksView: View {
    @Environment(\.openWindow) var openWindow

    @Bindable var rsyncUIdata: RsyncUIconfigurations
    // The object holds the progressdata for the current estimated task
    // which is executed. Data for progressview.
    @Bindable var progressdetails: ProgressDetails
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    /// Navigation path for executetasks
    @Binding var executetaskpath: [Tasks]
    /// For URL commands within RsyncUI
    @Binding var urlcommandestimateandsynchronize: Bool
    /// Show or hide Toolbox
    @Binding var columnVisibility: NavigationSplitViewVisibility
    /// Selected profile
    @Binding var selectedprofileID: ProfilesnamesRecord.ID?
    /// Save output from real synchronize task to logfile
    @State var saveactualsynclogdata: Bool = false

    // Focus buttons from the menu
    @State var focusstartestimation: Bool = false
    @State var focusstartexecution: Bool = false
    // Focus export and import
    @State var focusexport: Bool = false
    @State var focusimport: Bool = false
    // Local data for present local and remote info about task
    @State var selectedconfig: SynchronizeConfiguration?
    @State var doubleclick: Bool = false
    /// Alert button
    @State var showingAlert = false
    /// Progress synchronizing
    @State var progress: Double = 0
    /// Not used, only for parameter
    @State var maxcount: Double = 0
    // For estimates is true
    @State var thereareestimates: Bool = false
    @State var activeSheet: SheetType?
    @State var showquicktask: Bool = false

    var body: some View {
        TasksListPanelView(rsyncUIdata: rsyncUIdata,
                           selecteduuids: $selecteduuids,
                           doubleclick: $doubleclick,
                           progress: $progress,
                           progressdetails: progressdetails,
                           max: maxcount,
                           onSelectedUuidsChange: handleSelectedUuidsChange,
                           onEstimatedListChange: handleEstimatedListChange)
            .onChange(of: rsyncUIdata.profile) { reset() }
            .onChange(of: focusexport) {
                handleFocusExportChange()
            }
            .onChange(of: focusimport) {
                handleFocusImportChange()
            }
        .onChange(of: focusstartestimation) {
            if focusstartestimation { handleStartEstimation() }
        }
        .onChange(of: focusstartexecution) {
            guard focusstartexecution else { return }
            focusstartexecution = false
            execute()
        }
        .onChange(of: doubleclick) {
            guard doubleclick else { return }
            doubleclick = false
            doubleClickActionFunction()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SynchronizeActionBar(
                selectionCount: selecteduuids.count,
                canRun: canRun,
                preview: handleStartEstimation,
                synchronize: execute
            )
        }
        .navigationTitle("RsyncUI")
        .focusedSceneValue(\.startestimation, $focusstartestimation)
        .focusedSceneValue(\.startexecution, $focusstartexecution)
        .focusedSceneValue(\.exporttasks, $focusexport)
        .focusedSceneValue(\.importtasks, $focusimport)
        .focusedSceneValue(\.showquicktask, $showquicktask)
        .toolbar { taskviewtoolbarcontent }
        .sheet(isPresented: $showingAlert) {
            SynchronizeConfirmationView(
                configurations: runnableConfigurations,
                incompletePreview: progressdetails.profile == rsyncUIdata.profile && (progressdetails.estimatedlist ?? []).contains { estimate in
                    runnableConfigurations.contains { $0.id == estimate.id } && !estimate.hasUsableStatistics
                },
                estimatedIDs: estimatedRunScope,
                cancel: { showingAlert = false },
                preview: {
                    showingAlert = false
                    executetaskpath.append(Tasks(task: .summarizeddetailsview))
                },
                synchronize: {
                    showingAlert = false
                    rsyncUIdata.executetasksinprogress = true
                    executetaskpath.append(Tasks(task: .executenoestimatetasksview))
                },
                synchronizeEstimated: {
                    showingAlert = false
                    let scope = estimatedRunScope
                    guard !scope.isEmpty else { return }
                    selecteduuids = scope
                    rsyncUIdata.executetasksinprogress = true
                    executetaskpath.append(Tasks(task: .executestimatedview))
                }
            )
        }
        .sheet(item: $activeSheet) { sheetType in
            switch sheetType {
            case .exportview:
                if let configurations = rsyncUIdata.configurations {
                    ExportView(activeSheet: $activeSheet,
                               configurations: configurations,
                               preselectedtasks: selecteduuids)
                        .onDisappear {
                            selecteduuids.removeAll()
                            activeSheet = nil
                        }
                }
            case .importview:
                ImportView(rsyncUIdata: rsyncUIdata,
                           activeSheet: $activeSheet,
                           maxhiddenID: MaxhiddenID().computemaxhiddenID(rsyncUIdata.configurations))
                    .onDisappear {
                        activeSheet = nil
                    }
            }
        }
    }
}

extension TasksView {
    func handleSelectedUuidsChange() {
        if let configurations = rsyncUIdata.configurations {
            if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                selectedconfig = configurations[index]
                // Must check if rsync version and snapshot
                if configurations[index].task == SharedReference.shared.snapshot,
                   SharedReference.shared.rsyncversion3 == false {
                    selecteduuids.removeAll()
                }
            } else {
                selectedconfig = nil
            }
        }
        progressdetails.uuidswithdatatosynchronize = selecteduuids
    }

    func handleEstimatedListChange() {
        thereareestimates = progressdetails.estimatedlist != nil
    }

    func handleFocusExportChange() {
        guard focusexport == true else { return }
        activeSheet = .exportview
        focusexport = false
    }

    func handleFocusImportChange() {
        guard focusimport == true else { return }
        activeSheet = .importview
        focusimport = false
    }

    func handleStartEstimation() {
        focusstartestimation = false
        guard canRun else { return }
        executetaskpath.append(Tasks(task: .summarizeddetailsview))
    }

    func allTasksAreHalted() -> Bool {
        let haltedtasks = rsyncUIdata.configurations?.filter { $0.task == SharedReference.shared.halted }
        return haltedtasks?.count ?? 0 == rsyncUIdata.configurations?.count ?? 0
    }

    /// Double click action is discovered in the ListofTasksMainView
    /// Must do some checks her as well
    func doubleClickActionFunction() {
        guard SharedReference.shared.norsync == false else { return }
        // Must check if task is halted
        guard selectedconfig?.task != SharedReference.shared.halted else {
            return
        }

        if progressdetails.estimatedlist == nil {
            dryRun()
        } else if progressdetails.onlySelectedTaskIsEstimated(selecteduuids) {
            // Only execute task if this task only is estimated
            execute()
        } else {
            dryRun()
        }
    }

    func dryRun() {
        if selectedconfig != nil,
           progressdetails.estimatedlist?.count ?? 0 == 0 {
            doubleclick = false
            executetaskpath.append(Tasks(task: .onetaskdetailsview))
        } else if selectedconfig != nil,
                  progressdetails.executeAnotherDryRun(rsyncUIdata.profile) == true {
            doubleclick = false
            executetaskpath.append(Tasks(task: .onetaskdetailsview))
        } else if selectedconfig != nil,
                  progressdetails.allTasksEstimated(rsyncUIdata.profile) == false {
            doubleclick = false
            executetaskpath.append(Tasks(task: .onetaskdetailsview))
        }
    }

    func execute() {
        guard canRun else { return }
        let scope = Set(runnableConfigurations.map(\.id))
        let estimates = progressdetails.estimatedlist ?? []
        guard progressdetails.profile == rsyncUIdata.profile,
              Self.hasPreview(for: scope, estimatedIDs: Set(estimates.filter(\.hasUsableStatistics).map(\.id))) else {
            showingAlert = true
            return
        }
        if !selecteduuids.isEmpty {
            selecteduuids = scope
        }
        rsyncUIdata.executetasksinprogress = true
        executetaskpath.append(Tasks(task: .executestimatedview))
    }

    static func hasPreview(for scope: Set<UUID>, estimatedIDs: Set<UUID>) -> Bool {
        !scope.isEmpty && scope.isSubset(of: estimatedIDs)
    }

    /// Tasks in scope with usable statistics and changes to synchronize
    static func estimatedRunScope(for scope: Set<UUID>, estimates: [RemoteDataNumbers]) -> Set<UUID> {
        Set(estimates.filter { $0.hasUsableStatistics && $0.datatosynchronize }.map(\.id)).intersection(scope)
    }

    private var estimatedRunScope: Set<UUID> {
        guard progressdetails.profile == rsyncUIdata.profile else { return [] }
        return Self.estimatedRunScope(for: Set(runnableConfigurations.map(\.id)),
                                      estimates: progressdetails.estimatedlist ?? [])
    }

    private var runnableConfigurations: [SynchronizeConfiguration] {
        (rsyncUIdata.configurations ?? []).filter {
            $0.task != SharedReference.shared.halted && (selecteduuids.isEmpty || selecteduuids.contains($0.id))
        }
    }

    private var canRun: Bool {
        !SharedReference.shared.norsync && !runnableConfigurations.isEmpty
    }

    func reset() {
        progressdetails.resetCounts()
        selectedconfig = nil
        thereareestimates = false
        rsyncUIdata.executetasksinprogress = false
    }
}

private struct SynchronizeActionBar: View {
    let selectionCount: Int
    let canRun: Bool
    let preview: () -> Void
    let synchronize: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    scope
                    Spacer(minLength: 12)
                    actions
                }
                VStack(alignment: .trailing, spacing: 8) {
                    scope
                    actions
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(.bar)
    }

    private var scope: some View {
        Label {
            if selectionCount == 0 {
                Text("All enabled tasks")
            } else {
                Text("\(selectionCount) selected")
            }
        } icon: {
            Image(systemName: "checklist")
        }
        .font(.callout)
        .foregroundStyle(.secondary)
    }

    private var actions: some View {
        HStack {
            Button("Estimate (Dry Run)", action: preview)
                .help("Estimate (Dry Run) (⌘E)")
            Button("Synchronize", systemImage: "play.fill", action: synchronize)
                .buttonStyle(.borderedProminent)
                .help("Synchronize (⌘R)")
        }
        .disabled(!canRun)
    }
}
