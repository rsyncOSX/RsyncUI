//
//  TasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import Observation
import OSLog
import SwiftUI

struct CopyItem: Identifiable, Codable, Transferable {
    let id: UUID
    let task: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}

struct TasksView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    // The object holds the progressdata for the current estimated task
    // which is executed. Data for progressview.
    @Bindable var progressdetails: ProgressDetails
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
    @State private var importorexport: Bool = false
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

    @State var isOpen: Bool = false

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
                               SharedReference.shared.rsyncversion3 == false
                            {
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
                    importorexport = focusexport
                }
                .onChange(of: focusimport) {
                    importorexport = focusimport
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
        .toolbar(content: {
            ToolbarItem {
                if GlobalTimer.shared.timer != nil,
                   columnVisibility == .detailOnly
                {
                    MessageView(mytext: GlobalTimer.shared.schedule ?? "", size: .caption2)
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
                            Logger.process.info("TasksView: MAGIC WAND button selected task is halted, bailing out")
                            return
                        }
                    }
                    guard selecteduuids.count > 0 || rsyncUIdata.configurations?.count ?? 0 > 0 else {
                        Logger.process.info("TasksView: MAGIC WAND button no tasks selected, no configurations, bailing out")
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
                            Logger.process.info("TasksView: PLAY button selected task is halted, bailing out")
                            return
                        }
                    }

                    guard selecteduuids.count > 0 || rsyncUIdata.configurations?.count ?? 0 > 0 else {
                        Logger.process.info("TasksView: PLAY button selected, no configurations, bailing out")
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
                Spacer()
            }

            Group {
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
                    Button {
                        guard selecteduuids.count > 0 else { return }
                        guard alltasksarehalted() == false else { return }

                        guard selecteduuids.count == 1 else {
                            executetaskpath.append(Tasks(task: .summarizeddetailsview))
                            return
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
                        executetaskpath.append(Tasks(task: .viewlogfile))
                    } label: {
                        Image(systemName: "doc.plaintext")
                    }
                    .help("View logfile")
                }

                ToolbarItem {
                    Button {
                        executetaskpath.append(Tasks(task: .quick_synchronize))
                    } label: {
                        Image(systemName: "hare")
                    }
                    .help("Quick synchronize")
                }

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
            }

        })
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Synchronize all tasks with NO estimating first?"),
                primaryButton: .default(Text("Synchronize")) {
                    executetaskpath.append(Tasks(task: .executenoestimatetasksview))
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $importorexport) {
            if focusexport {
                if let configurations = rsyncUIdata.configurations {
                    ExportView(focusexport: $focusexport,
                               configurations: configurations,
                               preselectedtasks: selecteduuids)
                        .onDisappear {
                            selecteduuids.removeAll()
                        }
                }

            } else {
                ImportView(focusimport: $focusimport,
                           rsyncUIdata: rsyncUIdata,
                           maxhiddenID: MaxhiddenID().computemaxhiddenID(rsyncUIdata.configurations))
            }
        }
    }

    var doubleclickaction: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                doubleclickactionfunction()
                doubleclick = false
            })
    }

    var labelstartestimation: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                executetaskpath.append(Tasks(task: .summarizeddetailsview))
                focusstartestimation = false
            })
    }

    var labelstartexecution: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                execute()
                focusstartexecution = false
            })
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
            Logger.process.info("Doubleclick: task is halted")
            return
        }

        if progressdetails.estimatedlist == nil {
            dryrun()
        } else if progressdetails.onlyselectedtaskisestimated(selecteduuids) {
            // Only execute task if this task only is estimated
            Logger.process.info("Doubleclick: execute a real run for one task only")
            execute()
        } else {
            dryrun()
        }
    }

    func dryrun() {
        if selectedconfig != nil,
           progressdetails.estimatedlist?.count ?? 0 == 0
        {
            Logger.process.info("TasksView: DryRun() execute a dryrun for one task only")
            doubleclick = false
            executetaskpath.append(Tasks(task: .onetaskdetailsview))
        } else if selectedconfig != nil,
                  progressdetails.executeanotherdryrun(rsyncUIdata.profile) == true
        {
            Logger.process.info("TasksView: DryRun() new task same profile selected, execute a dryrun")
            doubleclick = false
            executetaskpath.append(Tasks(task: .onetaskdetailsview))

        } else if selectedconfig != nil,
                  progressdetails.alltasksestimated(rsyncUIdata.profile) == false
        {
            Logger.process.info("TasksView: DryRun() profile is changed, new task selected, execute a dryrun")
            doubleclick = false
            executetaskpath.append(Tasks(task: .onetaskdetailsview))
        }
    }

    func execute() {
        // All tasks are estimated and ready for execution.
        rsyncUIdata.executetasksinprogress = true
        if selecteduuids.count == 0,
           progressdetails.alltasksestimated(rsyncUIdata.profile) == true

        {
            Logger.process.info("TasksView: Execute() ALL estimated tasks")
            // Execute all estimated tasks
            selecteduuids = progressdetails.getuuidswithdatatosynchronize()
            // Change view, see SidebarTasksView
            executetaskpath.append(Tasks(task: .executestimatedview))

        } else if selecteduuids.count >= 1,
                  progressdetails.tasksareestimated(selecteduuids) == true

        {
            // One or some tasks are selected and estimated
            Logger.process.info("TasksView: Execute() ESTIMATED tasks only")
            // Execute estimated tasks only
            selecteduuids = progressdetails.getuuidswithdatatosynchronize()
            // Change view, see SidebarTasksView
            executetaskpath.append(Tasks(task: .executestimatedview))

        } else {
            // Execute all tasks, no estimate
            Logger.process.info("TasksView: Execute() selected or all tasks NO ESTIMATE")
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
