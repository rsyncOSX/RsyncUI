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
    @SwiftUI.Environment(RsyncUIconfigurations.self) private var rsyncUIdata
    // The object holds the progressdata for the current estimated task
    // which is executed. Data for progressview.
    @EnvironmentObject var progressdetails: ExecuteProgressDetails
    // These two objects keeps track of the state and collects
    // the estimated values.
    @State private var estimatingstate = EstimatingState()
    @State private var estimatingprogresscount = EstimateProgressDetails()

    @Binding var reload: Bool
    @Binding var selecteduuids: Set<UUID>

    @Binding var showeexecutestimatedview: Bool
    @Binding var showexecutenoestimateview: Bool
    @Binding var showexecutenoestiamteonetask: Bool

    // Focus buttons from the menu
    @State private var focusstartestimation: Bool = false
    @State private var focusstartexecution: Bool = false
    @State private var focusfirsttaskinfo: Bool = false
    @State private var focusdeletetask: Bool = false
    @State private var focusshowinfotask: Bool = false
    @State private var focusaborttask: Bool = false
    @State private var focusenabletimer: Bool = false

    @State private var filterstring: String = ""
    // Delete
    @State private var confirmdelete: Bool = false
    // Local data for present local and remote info about task
    @State private var localdata: [String] = []
    // Modale view
    @State private var modaleview = false
    @State private var sheetchooser = SheetChooser()
    @State private var selectedconfig = Selectedconfig()
    // Timer
    @State private var timervalue: Double = 600
    @State private var timerisenabled: Bool = false

    var actions: Actions
    // Reload and show table data
    @Binding var reloadtasksviewlist: Bool
    // Double click, only for macOS13 and later
    @State private var doubleclick: Bool = false

    var body: some View {
        ZStack {
            if reloadtasksviewlist == false {
                ListofTasksMainView(
                    selecteduuids: $selecteduuids,
                    filterstring: $filterstring,
                    reload: $reload,
                    confirmdelete: $confirmdelete,
                    reloadtasksviewlist: $reloadtasksviewlist,
                    doubleclick: $doubleclick
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
            } else {
                notifycompleted
            }

            // Remember max 10 in one Group
            Group {
                if focusstartestimation { labelstartestimation }
                if focusstartexecution { labelstartexecution }
                if focusfirsttaskinfo { labelfirsttime }
                if focusdeletetask { labeldeletetask }
                if focusshowinfotask { showinfotask }
                if focusaborttask { labelaborttask }
                if focusenabletimer { labelenabletimer }
                if estimatingprogresscount.estimateasync { progressviewestimateasync }
                if doubleclick { doubleclickaction }
            }
        }

        Spacer()

        HStack {
            VStack(alignment: .center) {
                HStack {
                    Button("Estimate") {
                        let action = ActionHolder(action: "Estimate", profile: rsyncUIdata.profile ?? "Default profile", source: "TasksView")
                        actions.addaction(action)
                        estimate()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .tooltip("Shortcut ⌘E")

                    Button("Execute") { execute() }
                        .buttonStyle(PrimaryButtonStyle())
                        .tooltip("Shortcut ⌘R")

                    Button("Reset") {
                        let action = ActionHolder(action: "Reset", profile: rsyncUIdata.profile ?? "Default profile", source: "TasksView")
                        actions.addaction(action)
                        selecteduuids.removeAll()
                        reset()
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("List") {
                        sheetchooser.sheet = .alltasksview
                        modaleview = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }

            Spacer()

            Button("Abort") { abort() }
                .buttonStyle(AbortButtonStyle())
                .tooltip("Shortcut ⌘A")
        }
        .focusedSceneValue(\.startestimation, $focusstartestimation)
        .focusedSceneValue(\.startexecution, $focusstartexecution)
        .focusedSceneValue(\.firsttaskinfo, $focusfirsttaskinfo)
        .focusedSceneValue(\.deletetask, $focusdeletetask)
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
    }

    @ViewBuilder
    func makeSheet() -> some View {
        switch sheetchooser.sheet {
        case .dryrunalreadyestimated:
            DetailsViewAlreadyEstimated(estimatedlist: estimatingprogresscount.getestimatedlist() ?? [],
                                        selectedconfig: selectedconfig.config)
        case .dryrun:
            OutputEstimatedView(selecteduuids: $selecteduuids,
                                execute: $focusstartexecution,
                                estimatedlist: estimatingprogresscount.getestimatedlist() ?? [])
        case .estimateddetailsview:
            DetailsView(selectedconfig: selectedconfig.config)
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
                    if selecteduuids.isEmpty == false {
                        let estimateonetaskasync =
                            EstimateOnetaskAsync(configurations: rsyncUIdata,
                                                 updateinprogresscount: estimatingprogresscount,
                                                 hiddenID: selectedconfig.config?.hiddenID)
                        await estimateonetaskasync.execute()
                    } else {
                        let estimatealltasksasync =
                            EstimateAlltasksAsync(profile: rsyncUIdata.profile,
                                                  configurations: rsyncUIdata,
                                                  updateinprogresscount: estimatingprogresscount,
                                                  uuids: selecteduuids,
                                                  filter: filterstring)
                        await estimatealltasksasync.startexecution()
                    }
                }
            }
            .onDisappear {
                sheetchooser.sheet = .dryrun
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
                let tasklocalinfo = RsyncAsync(arguments: argumentslocalinfo,
                                               processtermination: processtermination)
                Task {
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

    var labeldeletetask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusdeletetask = false
                confirmdelete = true
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

    var notifycompleted: some View {
        notifymessage("Completed")
            .onAppear(perform: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    reloadtasksviewlist = false
                }
            })
            .frame(maxWidth: .infinity)
    }
}

extension TasksView {
    func doubleclickactionfunction() {
        if estimatingprogresscount.getestimatedlist() == nil {
            dryrun()
        } else if estimatingprogresscount.taskisestimated(selectedconfig.config?.hiddenID ?? -1) {
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
            let action = ActionHolder(action: "DryRun: execute a dryrun for one task only", profile: rsyncUIdata.profile ?? "Default profile", source: "DetailsView")
            actions.addaction(action)
            sheetchooser.sheet = .estimateddetailsview
        } else if selectedconfig.config != nil, estimatingprogresscount.alltasksestimated(rsyncUIdata.profile ?? "Default profile") {
            // DryRun: all tasks already estimated, show details on task
            let action = ActionHolder(action: "DryRun: all tasks already estimated, show details on task", profile: rsyncUIdata.profile ?? "Default profile", source: "DetailsViewAlreadyEstimated")
            actions.addaction(action)
            sheetchooser.sheet = .dryrunalreadyestimated
        } else if selectedconfig.config != nil, estimatingprogresscount.alltasksestimated(rsyncUIdata.profile ?? "Default profile") == false {
            // Profile is changed, new task selected
            // DryRun: profile is changed, new task selected, execute a dryrun
            let action = ActionHolder(action: "DryRun: profile is changed, new task selected, execute a dryrun", profile: rsyncUIdata.profile ?? "Default profile", source: "DetailsView")
            actions.addaction(action)
            sheetchooser.sheet = .estimateddetailsview
        } else if estimatingprogresscount.alltasksestimated(rsyncUIdata.profile ?? "Default profile") {
            // DryRun: show summarized dryrun for all tasks
            let action = ActionHolder(action: "DryRun: show summarized dryrun for all tasks", profile: rsyncUIdata.profile ?? "Default profile", source: "TasksView")
            actions.addaction(action)
            // show summarized dry run
            sheetchooser.sheet = .dryrun
        } else {
            // New profile is selected, just return no action
            return
        }
        modaleview = true
    }

    func estimate() {
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
        if estimatingprogresscount.alltasksestimated(rsyncUIdata.profile ?? "Default profile"),
           selectedconfig.config == nil
        {
            let action = ActionHolder(action: "Execute() all estimated tasks", profile: rsyncUIdata.profile ?? "Default profile", source: "ExecuteEstimatedTasksView")
            actions.addaction(action)
            // Execute all estimated tasks
            selecteduuids = estimatingprogresscount.getuuids()
            estimatingstate.updatestate(state: .start)
            // Change view, see SidebarTasksView
            showeexecutestimatedview = true
        } else if selectedconfig.config == nil,
                  estimatingprogresscount.alltasksestimated(rsyncUIdata.profile ?? "Default profile") == false
        {
            let action = ActionHolder(action: "Execute() all tasks NO estimate", profile: rsyncUIdata.profile ?? "Default profile", source: "ExecuteNoestimatedTasksView")
            actions.addaction(action)
            // Execute all tasks, no estimate
            showexecutenoestimateview = true
            showexecutenoestiamteonetask = false
        } else if selectedconfig.config != nil, estimatingprogresscount.alltasksestimated(rsyncUIdata.profile ?? "Default profile") == false {
            // Hack: if DryRun one task and Execute just after DryRun.
            // Execute as one task NO estimate. selecteduuids == 1 but inprogresscountmultipletask.getuuids() = 0
            if estimatingprogresscount.getuuids().count == 0 {
                let action = ActionHolder(action: "Execute() one task NO estimate", profile: rsyncUIdata.profile ?? "Default profile", source: "ExecuteNoestimateOneTaskView")
                actions.addaction(action)
                // Execute one task, no estimte
                showexecutenoestiamteonetask = true
                showexecutenoestimateview = false
            } else {
                let action = ActionHolder(action: "Execute() estimated tasks only", profile: rsyncUIdata.profile ?? "Default profile", source: "ExecuteEstimatedTasksView")
                actions.addaction(action)
                // Execute estimated tasks only
                // Execute all estimated tasks
                selecteduuids = estimatingprogresscount.getuuids()
                estimatingstate.updatestate(state: .start)
                // Change view, see SidebarTasksView
                showeexecutestimatedview = true
            }
        } else {
            let action = ActionHolder(action: "Execute() one task NO estimate", profile: rsyncUIdata.profile ?? "Default profile", source: "ExecuteNoestimateOneTaskView")
            actions.addaction(action)
            // Execute one task, no estimte
            showexecutenoestiamteonetask = true
            showexecutenoestimateview = false
        }
    }

    func reset() {
        progressdetails.resetcounter()
        estimatingprogresscount.resetcounts()
        estimatingstate.updatestate(state: .start)
        selectedconfig.config = nil
        estimatingprogresscount.estimateasync = false
        sheetchooser.sheet = .dryrun
    }

    func abort() {
        let action = ActionHolder(action: "Abort", profile: rsyncUIdata.profile ?? "Default profile", source: "TasksView")
        progressdetails.resetcounter()
        actions.addaction(action)
        selecteduuids.removeAll()
        estimatingstate.updatestate(state: .start)
        estimatingprogresscount.resetcounts()
        progressdetails.hiddenIDatwork = -1
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
        let action = ActionHolder(action: "Start Async Timer", profile: rsyncUIdata.profile ?? "Default profile", source: "TasksView")
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
        let action = ActionHolder(action: "Stop Async Timer", profile: rsyncUIdata.profile ?? "Default profile", source: "TasksView")
        actions.addaction(action)
        SharedReference.shared.workitem?.cancel()
        SharedReference.shared.workitem = nil
    }
}

enum Sheet: String, Identifiable {
    case dryrun, dryrunalreadyestimated, estimateddetailsview, alltasksview, firsttime, localremoteinfo, asynctimerison
    var id: String { rawValue }
}

@Observable
final class SheetChooser {
    var sheet: Sheet = .dryrun
}

@Observable
final class Selectedconfig {
    var config: Configuration?
}

// swiftlint:enable line_length type_body_length file_length
