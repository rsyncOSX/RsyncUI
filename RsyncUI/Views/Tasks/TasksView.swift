//
//  TasksSheetstateView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/03/2023.
//
// swiftlint:disable line_length file_length

import Observation
import OSLog
import SwiftUI

enum Sheet: String, Identifiable {
    case dryrunalltasks, dryrunalreadyestimated, dryrunonetask, alltasksview, firsttime // , asynctimerison
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

struct TasksView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    // The object holds the progressdata for the current estimated task
    // which is executed. Data for progressview.
    @EnvironmentObject var executeprogressdetails: ExecuteProgressDetails
    // These two objects keeps track of the state and collects
    // the estimated values.
    @State private var estimatingstate = EstimatingState()
    @State private var estimateprogressdetails = EstimateProgressDetails()

    @Binding var reload: Bool
    @Binding var selecteduuids: Set<Configuration.ID>

    @Binding var showeexecutestimatedview: Bool
    @Binding var showexecutenoestimateview: Bool

    // Focus buttons from the menu
    @State private var focusstartestimation: Bool = false
    @State private var focusstartexecution: Bool = false
    @State private var focusfirsttaskinfo: Bool = false
    @State private var focusaborttask: Bool = false
    // @State private var focusenabletimer: Bool = false

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
                if focusaborttask { labelaborttask }
                // if focusenabletimer { labelenabletimer }
                if estimateprogressdetails.estimatealltasksasync { progressviewestimateasync }
                if doubleclick { doubleclickaction }
            }
        }
        .focusedSceneValue(\.startestimation, $focusstartestimation)
        .focusedSceneValue(\.startexecution, $focusstartexecution)
        .focusedSceneValue(\.firsttaskinfo, $focusfirsttaskinfo)
        .focusedSceneValue(\.aborttask, $focusaborttask)
        // .focusedSceneValue(\.enabletimer, $focusenabletimer)
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
                }
                .help("Estimate (⌘E)")
            }

            ToolbarItem {
                Button {
                    execute()
                } label: {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .foregroundColor(Color(.blue))
                }
                .help("Synchronize (⌘R)")
            }

            ToolbarItem {
                Button {
                    selecteduuids.removeAll()
                    reset()
                } label: {
                    Image(systemName: "eraser")
                }
                .help("Reset estimates")
            }

            ToolbarItem {
                Button {
                    sheetchooser.sheet = .alltasksview
                    modaleview = true
                } label: {
                    Image(systemName: "list.bullet")
                }
                .help("List tasks all profiles")
            }

            ToolbarItem {
                Button {
                    detailsestimatedtask()
                } label: {
                    Image(systemName: "info")
                }
                .help("Rsync output estimated task")
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
                .help("Abort (⌘K)")
            }
        })
    }

    @ViewBuilder
    func makeSheet() -> some View {
        switch sheetchooser.sheet {
        case .dryrunalreadyestimated:
            DetailsOneTaskAlreadyEstimatedView(estimatedlist: estimateprogressdetails.getestimatedlist() ?? [],
                                               selectedconfig: selectedconfig.config)
        case .dryrunalltasks:
            DetailsSummarizedTasksView(selecteduuids: $selecteduuids,
                                       execute: $focusstartexecution,
                                       estimatedlist: estimateprogressdetails.getestimatedlist() ?? [])
        case .dryrunonetask:
            DetailsOneTaskView(selectedconfig: selectedconfig.config)
                .environment(estimateprogressdetails)
                .onAppear {
                    doubleclick = false
                }
                .onDisappear {
                    executeprogressdetails.setestimatedlist(estimateprogressdetails.getestimatedlist())
                }
        case .alltasksview:
            AlltasksView()
        case .firsttime:
            FirsttimeView()
            /*
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
              */
        }
    }

    var progressviewestimateasync: some View {
        AlertToast(displayMode: .alert, type: .loading)
            .onAppear {
                Task {
                    let estimate = EstimateTasksAsync(profile: rsyncUIdata.profile,
                                                      configurations: rsyncUIdata,
                                                      estimateprogressdetails: estimateprogressdetails,
                                                      uuids: selecteduuids,
                                                      filter: filterstring)
                    await estimate.startexecution()
                }
            }
            .onDisappear {
                sheetchooser.sheet = .dryrunalltasks
                modaleview = true
                focusstartestimation = false
                executeprogressdetails.resetcounts()
                executeprogressdetails.setestimatedlist(estimateprogressdetails.getestimatedlist())
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

    /*
        var labelenabletimer: some View {
            Label("", systemImage: "play.fill")
                .onAppear(perform: {
                    focusenabletimer = false
                    sheetchooser.sheet = .asynctimerison
                    modaleview = true
                })
        }
     */
}

extension TasksView {
    func doubleclickactionfunction() {
        if estimateprogressdetails.getestimatedlist() == nil {
            dryrun()
        } else if estimateprogressdetails.tasksareestimated(selecteduuids) {
            execute()
        } else {
            dryrun()
        }
    }

    func dryrun() {
        if selectedconfig.config != nil,
           estimateprogressdetails.getestimatedlist()?.count ?? 0 == 0
        {
            // DryRun: execute a dryrun for one task only
            Logger.process.info("DryRun: execute a dryrun for one task only")
            sheetchooser.sheet = .dryrunonetask
        } else if selectedconfig.config != nil,
                  estimateprogressdetails.alltasksestimated(rsyncUIdata.profile ?? "Default profile") == false
        {
            // Profile is changed, new task selected
            // DryRun: profile is changed, new task selected, execute a dryrun
            Logger.process.info("DryRun: profile is changed, new task selected, execute a dryrun")
            sheetchooser.sheet = .dryrunonetask
        } else if estimateprogressdetails.alltasksestimated(rsyncUIdata.profile ?? "Default profile") {
            // DryRun: show summarized dryrun for all tasks
            Logger.process.info("DryRun: show summarized dryrun for all tasks")
            // show summarized dry run
            sheetchooser.sheet = .dryrunalltasks
        }
        modaleview = true
    }

    func detailsestimatedtask() {
        // DryRun: all tasks already estimated, show details on task
        guard executeprogressdetails.taskisestimatedbyUUID(selectedconfig.config?.id ?? UUID()) == true else { return }
        Logger.process.info("DryRun: task is already estimated, show details on task")
        sheetchooser.sheet = .dryrunalreadyestimated
        modaleview = true
    }

    func estimate() {
        guard estimateprogressdetails.estimatealltasksasync == false else {
            Logger.process.info("TasksView: estimate already in progress")
            return
        }
        if selectedconfig.config != nil {
            let profile = selectedconfig.config?.profile ?? "Default profile"
            if profile != rsyncUIdata.profile {
                selecteduuids.removeAll()
                selectedconfig.config = nil
            }
        }
        estimateprogressdetails.resetcounts()
        executeprogressdetails.resetcounts()
        estimateprogressdetails.startestimateasync()
    }

    func execute() {
        // All tasks are estimated and ready for execution.
        if selecteduuids.count == 0,
           estimateprogressdetails.alltasksestimated(rsyncUIdata.profile ?? "Default profile") == true

        {
            Logger.process.info("Execute() all estimated tasks")
            // Execute all estimated tasks
            selecteduuids = estimateprogressdetails.getuuids()
            estimatingstate.updatestate(state: .start)
            // Change view, see SidebarTasksView
            showeexecutestimatedview = true

        } else if selecteduuids.count >= 1,
                  estimateprogressdetails.tasksareestimated(selecteduuids) == true

        {
            // One or some tasks are selected and estimated
            Logger.process.info("Execute() estimated tasks only")
            // Execute estimated tasks only
            // Execute all estimated tasks
            selecteduuids = estimateprogressdetails.getuuids()
            estimatingstate.updatestate(state: .start)
            // Change view, see SidebarTasksView
            showeexecutestimatedview = true
        } else {
            // Execute all tasks, no estimate
            Logger.process.info("Execute() selected or all tasks NO estimate")
            // Execute tasks, no estimate
            showexecutenoestimateview = true
        }
    }

    func reset() {
        executeprogressdetails.resetcounts()
        estimateprogressdetails.resetcounts()
        estimatingstate.updatestate(state: .start)
        selectedconfig.config = nil
        estimateprogressdetails.estimatealltasksasync = false
        sheetchooser.sheet = .dryrunalltasks
    }

    func abort() {
        executeprogressdetails.resetcounts()
        selecteduuids.removeAll()
        estimatingstate.updatestate(state: .start)
        estimateprogressdetails.resetcounts()
        _ = InterruptProcess()
        reload = true
        focusstartestimation = false
        focusstartexecution = false
    }

    // Async start and stop timer
    func startasynctimer() {
        Logger.process.info("Start Async Timer")
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
        Logger.process.info("Stop Async Timer")
        SharedReference.shared.workitem?.cancel()
        SharedReference.shared.workitem = nil
    }
}

// swiftlint:enable line_length file_length
