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

enum TypeofTask: String, CaseIterable, Identifiable, CustomStringConvertible {
    case synchronize
    case snapshot
    case syncremote

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

@Observable
final class Selectedconfig {
    var config: SynchronizeConfiguration?
}

struct TasksView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    // The object holds the progressdata for the current estimated task
    // which is executed. Data for progressview.
    @Bindable var progressdetails: ProgressDetails
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    // Navigation path for executetasks
    @Binding var path: [Tasks]
    // For URL commands within RsyncUI
    @Binding var urlcommandestimateandsynchronize: Bool
    // @Binding var urlcommandverify: Bool
    // Show or hide Toolbox
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Binding var selectedprofile: String?
    // View profiles on left
    @Binding var selectedprofileID: ProfilesnamesRecord.ID?

    @State private var estimatestate = EstimateState()
    // Focus buttons from the menu
    @State private var focusstartestimation: Bool = false
    @State private var focusstartexecution: Bool = false
    // Focus export and import
    @State private var focusexport: Bool = false
    @State private var focusimport: Bool = false
    @State private var importorexport: Bool = false
    // Filterstring
    @State private var filterstring: String = ""
    // Local data for present local and remote info about task
    @State var selectedconfig = Selectedconfig()
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
                    filterstring: $filterstring,
                    doubleclick: $doubleclick,
                    progress: $progress,
                    progressdetails: progressdetails,
                    max: maxcount
                )
                .frame(maxWidth: .infinity)
                .onChange(of: selecteduuids) {
                    if let configurations = rsyncUIdata.configurations {
                        if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                            selectedconfig.config = configurations[index]
                            // Must check if rsync version and snapshot
                            if configurations[index].task == SharedReference.shared.snapshot,
                               SharedReference.shared.rsyncversion3 == false
                            {
                                selecteduuids.removeAll()
                            }
                        } else {
                            selectedconfig.config = nil
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
                        Picker("", selection: $selectedprofileID) {
                            Text("Default")
                                .tag(nil as ProfilesnamesRecord.ID?)
                            ForEach(rsyncUIdata.validprofiles, id: \.self) { profile in
                                Text(profile.profilename)
                                    .tag(profile.id)
                            }
                        }
                        .frame(width: 180)
                        .padding([.bottom, .top, .trailing], 7)

                        if SharedReference.shared.newversion {
                            MessageView(mytext: "Update available", size: .caption2)
                                .padding()
                                .frame(width: 180)
                        }
                    }
                }
            }

            ToolbarItem {
                Button {
                    guard SharedReference.shared.norsync == false else { return }
                    guard alltasksarehalted() == false else { return }
                    // This only applies if one task is selected and that task is halted
                    // If more than one task is selected, any halted tasks are ruled out
                    guard selectedconfig.config?.task != SharedReference.shared.halted else { return }

                    guard selecteduuids.count > 0 || rsyncUIdata.configurations?.count ?? 0 > 0 else {
                        Logger.process.info("Estimate() no tasks selected, no configurations, bailing out")
                        return
                    }

                    path.append(Tasks(task: .summarizeddetailsview))
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
                    guard selectedconfig.config?.task != SharedReference.shared.halted else { return }

                    guard selecteduuids.count > 0 || rsyncUIdata.configurations?.count ?? 0 > 0 else {
                        Logger.process.info("Estimate() no tasks selected, no configurations, bailing out")
                        return
                    }
                    // Check if there are estimated tasks, if true execute the
                    // estimated tasks view
                    if progressdetails.estimatedlist?.count ?? 0 > 0 {
                        path.append(Tasks(task: .executestimatedview))
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
                        path.append(Tasks(task: .summarizeddetailsview))
                        return
                    }
                    if progressdetails.tasksareestimated(selecteduuids) {
                        path.append(Tasks(task: .dryrunonetaskalreadyestimated))
                    } else {
                        path.append(Tasks(task: .onetaskdetailsview))
                    }
                } label: {
                    Image(systemName: "text.magnifyingglass")
                }
                .help("Rsync output estimated task")
            }

            ToolbarItem {
                Button {
                    path.append(Tasks(task: .viewlogfile))
                } label: {
                    Image(systemName: "doc.plaintext")
                }
                .help("View logfile")
            }

            ToolbarItem {
                Button {
                    path.append(Tasks(task: .quick_synchronize))
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
        })
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Synchronize all tasks with NO estimating first?"),
                primaryButton: .default(Text("Synchronize")) {
                    path.append(Tasks(task: .executenoestimatetasksview))
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
                path.append(Tasks(task: .summarizeddetailsview))
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

    func doubleclickactionfunction() {
        guard SharedReference.shared.norsync == false else { return }
        // Must check if task is halted
        guard selectedconfig.config?.task != SharedReference.shared.halted  else {
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
        if selectedconfig.config != nil,
           progressdetails.estimatedlist?.count ?? 0 == 0
        {
            Logger.process.info("DryRun: execute a dryrun for one task only")
            doubleclick = false
            path.append(Tasks(task: .onetaskdetailsview))
        } else if selectedconfig.config != nil,
                  progressdetails.executeanotherdryrun(rsyncUIdata.profile) == true
        {
            Logger.process.info("DryRun: new task same profile selected, execute a dryrun")
            doubleclick = false
            path.append(Tasks(task: .onetaskdetailsview))

        } else if selectedconfig.config != nil,
                  progressdetails.alltasksestimated(rsyncUIdata.profile) == false
        {
            Logger.process.info("DryRun: profile is changed, new task selected, execute a dryrun")
            doubleclick = false
            path.append(Tasks(task: .onetaskdetailsview))
        }
    }

    func execute() {
        // All tasks are estimated and ready for execution.
        rsyncUIdata.executetasksinprogress = true
        if selecteduuids.count == 0,
           progressdetails.alltasksestimated(rsyncUIdata.profile) == true

        {
            Logger.process.info("Execute() all estimated tasks")
            // Execute all estimated tasks
            selecteduuids = progressdetails.getuuidswithdatatosynchronize()
            estimatestate.updateestimatestate(state: .start)
            // Change view, see SidebarTasksView
            path.append(Tasks(task: .executestimatedview))

        } else if selecteduuids.count >= 1,
                  progressdetails.tasksareestimated(selecteduuids) == true

        {
            // One or some tasks are selected and estimated
            Logger.process.info("Execute() estimated tasks only")
            // Execute estimated tasks only
            selecteduuids = progressdetails.getuuidswithdatatosynchronize()
            estimatestate.updateestimatestate(state: .start)
            // Change view, see SidebarTasksView
            path.append(Tasks(task: .executestimatedview))

        } else {
            // Execute all tasks, no estimate
            Logger.process.info("Execute() selected or all tasks NO estimate")
            // Execute tasks, no estimate
            showingAlert = true
        }
    }

    func reset() {
        progressdetails.resetcounts()
        estimatestate.updateestimatestate(state: .start)
        selectedconfig.config = nil
        thereareestimates = false
        rsyncUIdata.executetasksinprogress = false
    }
}
