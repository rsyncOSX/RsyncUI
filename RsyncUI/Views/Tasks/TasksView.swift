//
//  TasksSheetstateView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/03/2023.
//
// swiftlint:disable line_length type_body_length file_length

import Observation
import SwiftUI

struct TasksView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    // The object holds the progressdata for the current estimated task
    // which is executed. Data for progressview.
    @SwiftUI.Environment(\.executeprogressdetails) private var progressdetails
    // These two objects keeps track of the state and collects
    // the estimated values.
    @State private var estimatingstate = EstimatingState()
    @State private var estimatingprogresscount = EstimateProgressDetails()

    @Binding var reload: Bool
    @Binding var selecteduuids: Set<Configuration.ID>

    @Binding var showeexecutestimatedview: Bool
    @Binding var showexecutenoestimateview: Bool

    // Focus buttons from the menu
    @State private var focusstartestimation: Bool = false
    @State private var focusstartexecution: Bool = false
    @State private var focusfirsttaskinfo: Bool = false
    @State private var focusshowinfotask: Bool = false
    @State private var focusaborttask: Bool = false
    @State private var focusenabletimer: Bool = false

    @State private var filterstring: String = ""
    // Local data for present local and remote info about task
    @State private var localdata: [String] = []
    // Modale view
    @State private var modaleview = false
    @State var sheetchooser = SheetChooser()
    @State var selectedconfig = Selectedconfig()
    // Timer
    @State private var timervalue: Double = 600
    @State private var timerisenabled: Bool = false

    var actions: Actions
    // Double click, only for macOS13 and later
    @State private var doubleclick: Bool = false

    var body: some View {
        ZStack {
            ListofTasksMainView(
                selecteduuids: $selecteduuids,
                filterstring: $filterstring,
                reload: $reload,
                doubleclick: $doubleclick,
                showestimateicon: true
            )
            .frame(maxWidth: .infinity)
            .onChange(of: selecteduuids) {
                let selected = rsyncUIdata.configurations?.filter { config in
                    selecteduuids.contains(config.id)
                }
                if (selected?.count ?? 0) == 1 {
                    if let config = selected {
                        selectedconfig.config = config[0]
                    }
                } else {
                    selectedconfig.config = nil
                }
            }

            // Remember max 10 in one Group
            Group {
                if focusstartestimation { labelstartestimation }
                if focusstartexecution { labelstartexecution }
                if focusfirsttaskinfo { labelfirsttime }
                if focusshowinfotask { showinfotask }
                if focusaborttask { labelaborttask }
                if focusenabletimer { labelenabletimer }
                if estimatingprogresscount.estimateasync { progressviewestimateasync }
                if doubleclick { doubleclickaction }
            }

            if #unavailable(macOS 13) {
                Spacer()

                Button("DryRun") { dryrun() }
                    .buttonStyle(ColorfulButtonStyle())
            }
        }
        .focusedSceneValue(\.startestimation, $focusstartestimation)
        .focusedSceneValue(\.startexecution, $focusstartexecution)
        .focusedSceneValue(\.firsttaskinfo, $focusfirsttaskinfo)
        .focusedSceneValue(\.showinfotask, $focusshowinfotask)
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .focusedSceneValue(\.enabletimer, $focusenabletimer)
        .task {
            // Discover if firsttime use, if true present view for firsttime
            if SharedReference.shared.firsttime {
                sheetchooser.sheet = .firsttime
                modaleview = true
            }
        }
        .sheet(isPresented: $modaleview) { makeSheet() }
        .toolbar(content: {
            ToolbarItem {
                Button {
                    estimate()
                } label: {
                    Image(systemName: "wand.and.stars")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.blue, .blue)
                        .symbolEffect(.variableColor)
                }
                .tooltip("Estimate (⌘E)")
            }

            ToolbarItem {
                Button {
                    execute()
                } label: {
                    Image(systemName: "arrowshape.turn.up.backward")
                }
                .tooltip("Execute (⌘R)")
            }

            ToolbarItem {
                Button {
                    let action = ActionHolder(action: "Reset",
                                              profile: rsyncUIdata.profile ?? "Default profile",
                                              source: "TasksView")
                    actions.addaction(action)
                    selecteduuids.removeAll()
                    reset()
                } label: {
                    Image(systemName: "eraser")
                }
                .tooltip("Reset estimates")
            }

            ToolbarItem {
                Button {
                    sheetchooser.sheet = .alltasksview
                    modaleview = true
                } label: {
                    Image(systemName: "list.bullet")
                }
                .tooltip("List tasks all profiles")
            }

            ToolbarItem {
                Button {
                    detailsestimatedtask()
                } label: {
                    Image(systemName: "info")
                }
                .tooltip("Rsync output estimated task")
            }

            ToolbarItem {
                Spacer()
            }

            ToolbarItem {
                Button {
                    abort()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .tooltip("Abort (⌘K)")
            }
        })
    }

    @ViewBuilder
    func makeSheet() -> some View {
        switch sheetchooser.sheet {
        case .dryrunalreadyestimated:
            DetailsOneTaskAlreadyEstimatedView(estimatedlist: estimatingprogresscount.getestimatedlist() ?? [],
                                               selectedconfig: selectedconfig.config)
        case .dryrunalltasks:
            DetailsSummarizedTasksView(selecteduuids: $selecteduuids,
                                       execute: $focusstartexecution,
                                       estimatedlist: estimatingprogresscount.getestimatedlist() ?? [])
        case .dryrunonetask:
            DetailsOneTaskView(selectedconfig: selectedconfig.config)
                .environment(estimatingprogresscount)
                .onAppear {
                    doubleclick = false
                }
                .onDisappear {
                    progressdetails.setestimatedlist(estimatingprogresscount.getestimatedlist())
                }
        case .alltasksview:
            AlltasksView()
        case .firsttime:
            FirsttimeView()
        case .localremoteinfo:
            LocalRemoteInfoView(localdata: $localdata,
                                selectedconfig: selectedconfig.config)
        case .asynctimerison:
            Counter(timervalue: $timervalue,
                    timerisenabled: $timerisenabled)
                .onDisappear(perform: {
                    stopasynctimer()
                    timervalue = SharedReference.shared.timervalue ?? 600
                })
                .onChange(of: timerisenabled) {
                    if timerisenabled == true {
                        startasynctimer()
                    }
                }
        }
    }

    var progressviewestimateasync: some View {
        AlertToast(displayMode: .alert, type: .loading)
            .onAppear {
                Task {
                    let estimate = EstimateTasksAsync(profile: rsyncUIdata.profile,
                                                      configurations: rsyncUIdata,
                                                      updateinprogresscount: estimatingprogresscount,
                                                      uuids: selecteduuids,
                                                      filter: filterstring)
                    await estimate.startexecution()
                }
            }
            .onDisappear {
                sheetchooser.sheet = .dryrunalltasks
                modaleview = true
                focusstartestimation = false
                progressdetails.resetcounter()
                progressdetails.setestimatedlist(estimatingprogresscount.getestimatedlist())
            }
    }

    var showinfotask: some View {
        AlertToast(displayMode: .alert, type: .loading)
            .onAppear(perform: {
                let argumentslocalinfo = ArgumentsLocalcatalogInfo(config: selectedconfig.config)
                    .argumentslocalcataloginfo(dryRun: true, forDisplay: false)
                guard argumentslocalinfo != nil else {
                    focusshowinfotask = false
                    return
                }

                Task {
                    let tasklocalinfo = await RsyncAsync(arguments: argumentslocalinfo,
                                                         processtermination: processtermination)
                    await tasklocalinfo.executeProcess()
                }
            })
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
                estimate()
            })
    }

    var labelstartexecution: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                execute()
            })
    }

    var labelfirsttime: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusfirsttaskinfo = false
                sheetchooser.sheet = .firsttime
                modaleview = true
            })
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }

    var labelenabletimer: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusenabletimer = false
                sheetchooser.sheet = .asynctimerison
                modaleview = true
            })
    }
}

extension TasksView {
    func doubleclickactionfunction() {
        if estimatingprogresscount.getestimatedlist() == nil {
            dryrun()
        } else if estimatingprogresscount.tasksareestimated(selecteduuids) {
            execute()
        } else {
            dryrun()
        }
    }

    func dryrun() {
        if selectedconfig.config != nil,
           estimatingprogresscount.getestimatedlist()?.count ?? 0 == 0
        {
            // DryRun: execute a dryrun for one task only
            let action = ActionHolder(action: "DryRun: execute a dryrun for one task only",
                                      profile: rsyncUIdata.profile ?? "Default profile",
                                      source: "DetailsView")
            actions.addaction(action)
            sheetchooser.sheet = .dryrunonetask
        } else if selectedconfig.config != nil,
                  estimatingprogresscount.alltasksestimated(rsyncUIdata.profile ?? "Default profile") == false
        {
            // Profile is changed, new task selected
            // DryRun: profile is changed, new task selected, execute a dryrun
            let action = ActionHolder(action: "DryRun: profile is changed, new task selected, execute a dryrun",
                                      profile: rsyncUIdata.profile ?? "Default profile",
                                      source: "DetailsView")
            actions.addaction(action)
            sheetchooser.sheet = .dryrunonetask
        } else if estimatingprogresscount.alltasksestimated(rsyncUIdata.profile ?? "Default profile") {
            // DryRun: show summarized dryrun for all tasks
            let action = ActionHolder(action: "DryRun: show summarized dryrun for all tasks",
                                      profile: rsyncUIdata.profile ?? "Default profile",
                                      source: "TasksView")
            actions.addaction(action)
            // show summarized dry run
            sheetchooser.sheet = .dryrunalltasks
        } else {
            // New profile is selected, just return no action
            return
        }
        modaleview = true
    }

    func detailsestimatedtask() {
        // DryRun: all tasks already estimated, show details on task
        guard progressdetails.taskisestimatedbyUUID(selectedconfig.config?.id ?? UUID()) == true else { return }
        let action = ActionHolder(action: "DryRun: task is already estimated, show details on task",
                                  profile: rsyncUIdata.profile ?? "Default profile",
                                  source: "DetailsViewAlreadyEstimated")
        actions.addaction(action)
        sheetchooser.sheet = .dryrunalreadyestimated
        modaleview = true
    }

    func estimate() {
        let action = ActionHolder(action: "Estimate",
                                  profile: rsyncUIdata.profile ?? "Default profile",
                                  source: "TasksView")
        actions.addaction(action)
        if selectedconfig.config != nil {
            let profile = selectedconfig.config?.profile ?? "Default profile"
            if profile != rsyncUIdata.profile {
                selecteduuids.removeAll()
                selectedconfig.config = nil
            }
        }
        estimatingprogresscount.resetcounts()
        progressdetails.resetcounter()
        estimatingprogresscount.startestimateasync()
    }

    func execute() {
        // All tasks are estimated and ready for execution.
        if selecteduuids.count == 0,
           estimatingprogresscount.alltasksestimated(rsyncUIdata.profile ?? "Default profile") == true

        {
            let action = ActionHolder(action: "Execute() all estimated tasks",
                                      profile: rsyncUIdata.profile ?? "Default profile",
                                      source: "ExecuteEstimatedTasksView")
            actions.addaction(action)
            // Execute all estimated tasks
            selecteduuids = estimatingprogresscount.getuuids()
            estimatingstate.updatestate(state: .start)
            // Change view, see SidebarTasksView
            showeexecutestimatedview = true

        } else if selecteduuids.count >= 1,
                  estimatingprogresscount.tasksareestimated(selecteduuids) == true

        {
            // One or some tasks are selected and estimated
            let action = ActionHolder(action: "Execute() estimated tasks only",
                                      profile: rsyncUIdata.profile ?? "Default profile",
                                      source: "ExecuteEstimatedTasksView")
            actions.addaction(action)
            // Execute estimated tasks only
            // Execute all estimated tasks
            selecteduuids = estimatingprogresscount.getuuids()
            estimatingstate.updatestate(state: .start)
            // Change view, see SidebarTasksView
            showeexecutestimatedview = true
        } else {
            // Execute all tasks, no estimate
            let action = ActionHolder(action: "Execute() selected or all tasks NO estimate",
                                      profile: rsyncUIdata.profile ?? "Default profile",
                                      source: "ExecuteNoestimatedTasksView")
            actions.addaction(action)
            // Execute tasks, no estimate
            showexecutenoestimateview = true
        }
    }

    func reset() {
        progressdetails.resetcounter()
        estimatingprogresscount.resetcounts()
        estimatingstate.updatestate(state: .start)
        selectedconfig.config = nil
        estimatingprogresscount.estimateasync = false
        sheetchooser.sheet = .dryrunalltasks
    }

    func abort() {
        let action = ActionHolder(action: "Abort", profile: rsyncUIdata.profile ?? "Default profile", source: "TasksView")
        progressdetails.resetcounter()
        actions.addaction(action)
        selecteduuids.removeAll()
        estimatingstate.updatestate(state: .start)
        estimatingprogresscount.resetcounts()
        _ = InterruptProcess()
        reload = true
        focusstartestimation = false
        focusstartexecution = false
    }

    // For showinfo about one task
    func processtermination(data: [String]?) {
        localdata = data ?? []
        focusshowinfotask = false
        sheetchooser.sheet = .localremoteinfo
        modaleview = true
    }

    // Async start and stop timer
    func startasynctimer() {
        let action = ActionHolder(action: "Start Async Timer",
                                  profile: rsyncUIdata.profile ?? "Default profile",
                                  source: "TasksView")
        actions.addaction(action)
        SharedReference.shared.workitem = DispatchWorkItem {
            _ = Logfile(["Timer EXECUTED task on profile: " + (rsyncUIdata.profile ?? "")], error: true)
            execute()
        }
        let time = DispatchTime.now() + timervalue
        if let workitem = SharedReference.shared.workitem {
            DispatchQueue.main.asyncAfter(deadline: time, execute: workitem)
        }
    }

    func stopasynctimer() {
        let action = ActionHolder(action: "Stop Async Timer",
                                  profile: rsyncUIdata.profile ?? "Default profile",
                                  source: "TasksView")
        actions.addaction(action)
        SharedReference.shared.workitem?.cancel()
        SharedReference.shared.workitem = nil
    }
}

enum Sheet: String, Identifiable {
    case dryrunalltasks, dryrunalreadyestimated, dryrunonetask, alltasksview, firsttime, localremoteinfo, asynctimerison
    var id: String { rawValue }
}

@Observable
final class SheetChooser {
    // Which sheet to present
    // Do not redraw view when changing
    // no @Publised
    @ObservationIgnored
    var sheet: Sheet = .dryrunalltasks
}

@Observable
final class Selectedconfig {
    var config: Configuration?
}

// swiftlint:enable line_length type_body_length file_length
