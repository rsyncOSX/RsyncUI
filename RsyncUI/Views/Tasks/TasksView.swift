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
    @Environment(\.openWindow) private var openWindow

    @Bindable var rsyncUIdata: RsyncUIconfigurations
    // The object holds the progressdata for the current estimated task
    // which is executed. Data for progressview.
    @Bindable var progressdetails: ProgressDetails
    @Bindable var schedules: ObservableSchedules
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    // Navigation path for executetasks
    @Binding var executetaskpath: [Tasks]
    // For URL commands within RsyncUI
    @Binding var urlcommandestimateandsynchronize: Bool
    // Show or hide Toolbox
    @Binding var columnVisibility: NavigationSplitViewVisibility
    // Selected profile
    @Binding var selectedprofileID: ProfilesnamesRecord.ID?

    // Focus buttons from the menu
    @State private var focusstartestimation: Bool = false
    @State private var focusstartexecution: Bool = false
    // Focus export and import
    @State private var focusexport: Bool = false
    @State private var focusimport: Bool = false
    // Local data for present local and remote info about task
    @State var selectedconfig: SynchronizeConfiguration?
    @State private var doubleclick: Bool = false
    // Alert button
    @State private var showingAlert = false
    // Progress synchronizing
    @State private var progress: Double = 0
    // Not used, only for parameter
    @State private var maxcount: Double = 0
    // For estimates is true
    @State private var thereareestimates: Bool = false
    @State private var activeSheet: SheetType?
    @State private var showquicktask: Bool = false

    var body: some View {
        ZStack {
            HStack {
                ListofTasksMainView(
                    rsyncUIdata: rsyncUIdata,
                    selecteduuids: $selecteduuids,
                    doubleclick: $doubleclick,
                    progress: $progress,
                    progressdetails: progressdetails,
                    max: maxcount
                )
                .frame(maxWidth: .infinity)
                .onChange(of: selecteduuids) {
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
                .onChange(of: rsyncUIdata.profile) {
                    reset()
                }
                .onChange(of: progressdetails.estimatedlist) {
                    if progressdetails.estimatedlist == nil {
                        thereareestimates = false
                    } else {
                        thereareestimates = true
                    }
                }
                .onChange(of: focusexport) {
                    guard focusexport == true else { return }
                    activeSheet = .exportview
                    focusexport = false
                }
                .onChange(of: focusimport) {
                    // focusimport = true
                    guard focusimport == true else { return }
                    activeSheet = .importview
                    focusimport = false
                }

                Group {
                    if focusstartestimation { labelstartestimation }
                    if focusstartexecution { labelstartexecution }
                    if doubleclick { doubleclickaction }
                }
            }
        }
        .navigationTitle("Synchronize tasks: profile \(rsyncUIdata.profile ?? "Default")")
        .focusedSceneValue(\.startestimation, $focusstartestimation)
        .focusedSceneValue(\.startexecution, $focusstartexecution)
        .focusedSceneValue(\.exporttasks, $focusexport)
        .focusedSceneValue(\.importtasks, $focusimport)
        .focusedSceneValue(\.showquicktask, $showquicktask)
        .toolbar { taskviewtoolbarcontent }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Synchronize all tasks with NO estimating first?"),
                primaryButton: .default(Text("Synchronize")) {
                    executetaskpath.append(Tasks(task: .executenoestimatetasksview))
                },
                secondaryButton: .cancel()
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

    @ToolbarContentBuilder
    private var taskviewtoolbarcontent: some ToolbarContent {
        ToolbarItem {
            if GlobalTimer.shared.timerIsActive(),
               columnVisibility == .detailOnly {
                MessageView(mytext: GlobalTimer.shared.nextScheduleDate() ?? "", size: .caption2)
            }
        }

        ToolbarItem {
            if columnVisibility == .detailOnly {
                VStack {
                    if rsyncUIdata.validprofiles.isEmpty == false {
                        Picker("", selection: $selectedprofileID) {
                            Text("Default")
                                .tag(nil as ProfilesnamesRecord.ID?)
                            ForEach(rsyncUIdata.validprofiles, id: \.self) { profile in
                                Text(profile.profilename)
                                    .tag(profile.id)
                            }
                        }
                        // .frame(width: 180)
                        // .padding([.bottom, .top, .trailing], 7)
                    }

                    if SharedReference.shared.newversion {
                        MessageView(mytext: "Update available", size: .caption2)
                            .padding()
                            .frame(width: 180)
                    }
                }
            }
        }

        ToolbarItem {
            Spacer()
        }

        ToolbarItem {
            Button {
                guard SharedReference.shared.norsync == false else { return }
                guard alltasksarehalted() == false else { return }
                // This only applies if one task is selected and that task is halted
                // If more than one task is selected, any halted tasks are ruled out
                if let selectedconfig {
                    guard selectedconfig.task != SharedReference.shared.halted else {
                        return
                    }
                }
                guard selecteduuids.count > 0 || rsyncUIdata.configurations?.count ?? 0 > 0 else {
                    return
                }

                executetaskpath.append(Tasks(task: .summarizeddetailsview))
            } label: {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(Color(.blue))
            }
            .help("Estimate (⌘E)")
        }

        ToolbarItem {
            Button {
                guard SharedReference.shared.norsync == false else { return }
                guard alltasksarehalted() == false else { return }
                // This only applies if one task is selected and that task is halted
                // If more than one task is selected, any halted tasks are ruled out
                if let selectedconfig {
                    guard selectedconfig.task != SharedReference.shared.halted else {
                        return
                    }
                }

                guard selecteduuids.count > 0 || rsyncUIdata.configurations?.count ?? 0 > 0 else {
                    return
                }
                // Check if there are estimated tasks, if true execute the
                // estimated tasks view
                if progressdetails.estimatedlist?.count ?? 0 > 0 {
                    executetaskpath.append(Tasks(task: .executestimatedview))
                } else {
                    execute()
                }
            } label: {
                Image(systemName: "play.fill")
                    .foregroundColor(Color(.blue))
            }
            .help("Synchronize (⌘R)")
        }

        ToolbarItem {
            Button {
                selecteduuids.removeAll()
                reset()
            } label: {
                if thereareestimates == true {
                    Image(systemName: "clear")
                        .foregroundColor(Color(.red))
                } else {
                    Image(systemName: "clear")
                }
            }
            .help("Reset estimates")
        }

        ToolbarItem {
            Spacer()
        }

        Group {
            if showquicktask {
                ToolbarItem {
                    Button {
                        guard selecteduuids.count > 0 else { return }
                        guard alltasksarehalted() == false else { return }

                        guard selecteduuids.count == 1 else {
                            executetaskpath.append(Tasks(task: .summarizeddetailsview))
                            return
                        }

                        if selecteduuids.count == 1 {
                            guard selectedconfig?.task != SharedReference.shared.halted else {
                                return
                            }
                        }

                        if progressdetails.tasksareestimated(selecteduuids) {
                            executetaskpath.append(Tasks(task: .dryrunonetaskalreadyestimated))
                        } else {
                            executetaskpath.append(Tasks(task: .onetaskdetailsview))
                        }
                    } label: {
                        Image(systemName: "text.magnifyingglass")
                    }
                    .help("Rsync output estimated task")
                }

                ToolbarItem {
                    Button {
                        executetaskpath.append(Tasks(task: .quick_synchronize))
                    } label: {
                        Image(systemName: "hare")
                    }
                    .help("Quick synchronize")
                }

                ToolbarItem {
                    Button {
                        executetaskpath.append(Tasks(task: .charts))
                    } label: {
                        Image(systemName: "chart.bar.fill")
                    }
                    .help("Charts")
                    .disabled(selecteduuids.count != 1 || selectedconfig?.task == SharedReference.shared.syncremote)
                }

                ToolbarItem {
                    Button {
                        activeSheet = .scheduledtasksview
                    } label: {
                        Image(systemName: "calendar.circle.fill")
                    }
                    .help("Schedule")
                }

                ToolbarItem {
                    Spacer()
                }

                ToolbarItem {
                    Button {
                        openWindow(id: "rsyncuilog")
                    } label: {
                        Image(systemName: "doc.plaintext")
                    }
                    .help("View logfile")
                }

                ToolbarItem {
                    Button {
                        openWindow(id: "liversynclog")
                    } label: {
                        Image(systemName: "square.and.arrow.down.badge.checkmark")
                    }
                    .help("Rsync output")
                }
            }
        }

        ToolbarItem {
            Spacer()
        }

        Group {
            if alltasksarehalted() == false {
                ToolbarItem {
                    Button {
                        if urlcommandestimateandsynchronize {
                            urlcommandestimateandsynchronize = false
                        } else {
                            urlcommandestimateandsynchronize = true
                        }
                    } label: {
                        Image(systemName: "bolt.shield.fill")
                            .foregroundColor(Color(.yellow))
                    }
                    .help("Estimate & Synchronize")
                }
            }

            if SharedReference.shared.hideverifyremotefunction == false,
               SharedReference.shared.rsyncversion3,
               rsyncUIdata.oneormoretasksissnapshot == false,
               rsyncUIdata.oneormoresynchronizetasksisremoteVer3x {
                ToolbarItem {
                    Button {
                        openWindow(id: "verify")
                    } label: {
                        Image(systemName: "bolt.shield")
                            .foregroundColor(Color(.yellow))
                    }
                    .help("Verify remote")
                }
            }
        }
    }

    var doubleclickaction: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear {
                doubleclickactionfunction()
                doubleclick = false
            }
    }

    var labelstartestimation: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear {
                executetaskpath.append(Tasks(task: .summarizeddetailsview))
                focusstartestimation = false
            }
    }

    var labelstartexecution: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear {
                execute()
                focusstartexecution = false
            }
    }
}

extension TasksView {
    private func alltasksarehalted() -> Bool {
        let haltedtasks = rsyncUIdata.configurations?.filter { $0.task == SharedReference.shared.halted }
        return haltedtasks?.count ?? 0 == rsyncUIdata.configurations?.count ?? 0
    }

    // Double click action is discovered in the ListofTasksMainView
    // Must do some checks her as well
    func doubleclickactionfunction() {
        guard SharedReference.shared.norsync == false else { return }
        // Must check if task is halted
        guard selectedconfig?.task != SharedReference.shared.halted else {
            return
        }

        if progressdetails.estimatedlist == nil {
            dryrun()
        } else if progressdetails.onlyselectedtaskisestimated(selecteduuids) {
            // Only execute task if this task only is estimated
            execute()
        } else {
            dryrun()
        }
    }

    func dryrun() {
        if selectedconfig != nil,
           progressdetails.estimatedlist?.count ?? 0 == 0 {
            doubleclick = false
            executetaskpath.append(Tasks(task: .onetaskdetailsview))
        } else if selectedconfig != nil,
                  progressdetails.executeanotherdryrun(rsyncUIdata.profile) == true {
            doubleclick = false
            executetaskpath.append(Tasks(task: .onetaskdetailsview))

        } else if selectedconfig != nil,
                  progressdetails.alltasksestimated(rsyncUIdata.profile) == false {
            doubleclick = false
            executetaskpath.append(Tasks(task: .onetaskdetailsview))
        }
    }

    func execute() {
        // All tasks are estimated and ready for execution.
        rsyncUIdata.executetasksinprogress = true
        if selecteduuids.count == 0,
           progressdetails.alltasksestimated(rsyncUIdata.profile) == true {
            // Execute all estimated tasks
            selecteduuids = progressdetails.getuuidswithdatatosynchronize()
            // Change view, see SidebarTasksView
            executetaskpath.append(Tasks(task: .executestimatedview))

        } else if selecteduuids.count >= 1,
                  progressdetails.tasksareestimated(selecteduuids) == true {
            // One or some tasks are selected and estimated
            // Execute estimated tasks only
            selecteduuids = progressdetails.getuuidswithdatatosynchronize()
            // Change view, see SidebarTasksView
            executetaskpath.append(Tasks(task: .executestimatedview))

        } else {
            // Execute all tasks, no estimate
            // Execute tasks, no estimate, ask to execute
            showingAlert = true
        }
    }

    func reset() {
        progressdetails.resetcounts()
        selectedconfig = nil
        thereareestimates = false
        rsyncUIdata.executetasksinprogress = false
    }
}
