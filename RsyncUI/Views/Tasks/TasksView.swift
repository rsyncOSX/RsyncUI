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
    case scheduledtasksview

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
    @Bindable var schedules: ObservableSchedules
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
        ZStack {
            HStack {
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

                TasksFocusActionsView(focusStartEstimation: $focusstartestimation,
                                      focusStartExecution: $focusstartexecution,
                                      doubleClick: $doubleclick,
                                      onStartEstimation: handleStartEstimation,
                                      onStartExecution: execute,
                                      onDoubleClick: doubleClickActionFunction)
            }
        }
        .navigationTitle("Synchronize tasks: profile \(rsyncUIdata.profile ?? "Default")")
        .focusedSceneValue(\.startestimation, $focusstartestimation)
        .focusedSceneValue(\.startexecution, $focusstartexecution)
        .focusedSceneValue(\.exporttasks, $focusexport)
        .focusedSceneValue(\.importtasks, $focusimport)
        .focusedSceneValue(\.showquicktask, $showquicktask)
        .toolbar { taskviewtoolbarcontent }
        .alert("Synchronize all tasks with NO estimating first?", isPresented: $showingAlert) {
            Button("Synchronize") {
                executetaskpath.append(Tasks(task: .executenoestimatetasksview))
            }
            Button("Cancel", role: .cancel) {}
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
            case .scheduledtasksview:
                CalendarMonthView(rsyncUIdata: rsyncUIdata,
                                  schedules: schedules,
                                  selectedprofileID: $selectedprofileID,
                                  activeSheet: $activeSheet)
                    .frame(minWidth: 1100, idealWidth: 1200, minHeight: 550)
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
        executetaskpath.append(Tasks(task: .summarizeddetailsview))
        focusstartestimation = false
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
        // All tasks are estimated and ready for execution.
        rsyncUIdata.executetasksinprogress = true
        if selecteduuids.count == 0,
           progressdetails.allTasksEstimated(rsyncUIdata.profile) == true {
            // Execute all estimated tasks
            selecteduuids = progressdetails.getUUIDsWithDataToSynchronize()
            // Change view, see SidebarTasksView
            executetaskpath.append(Tasks(task: .executestimatedview))
        } else if selecteduuids.count >= 1,
                  progressdetails.tasksAreEstimated(selecteduuids) == true {
            // One or some tasks are selected and estimated
            // Execute estimated tasks only
            selecteduuids = progressdetails.getUUIDsWithDataToSynchronize()
            // Change view, see SidebarTasksView
            executetaskpath.append(Tasks(task: .executestimatedview))
        } else {
            // Execute all tasks, no estimate
            // Execute tasks, no estimate, ask to execute
            showingAlert = true
        }
    }

    func reset() {
        progressdetails.resetCounts()
        selectedconfig = nil
        thereareestimates = false
        rsyncUIdata.executetasksinprogress = false
    }
}
