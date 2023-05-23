//
//  TasksSheetstateView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/03/2023.
//
// swiftlint:disable line_length

import Network
import SwiftUI

struct TasksView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    // The object holds the progressdata for the current estimated task
    // which is executed. Data for progressview.
    @EnvironmentObject var executedetails: InprogressCountExecuteOneTaskDetails
    // These two objects keeps track of the state and collects
    // the estimated values.
    @StateObject private var estimationstate = EstimationState()
    @StateObject private var inprogresscountmultipletask = InprogressCountMultipleTasks()

    @Binding var reload: Bool
    @Binding var selecteduuids: Set<UUID>

    @Binding var showeexecutestimatedview: Bool
    @Binding var showexecutenoestimateview: Bool
    @Binding var showexecutenoestiamteonetask: Bool

    @State private var inwork: Int = -1

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
    @StateObject var sheetchooser = SheetChooser()
    @StateObject var selectedconfig = Selectedconfig()
    // Timer
    @State private var timervalue: Double = 600
    @State private var timerisenabled: Bool = false

    var body: some View {
        ZStack {
            ListofTasksView(
                selecteduuids: $selecteduuids.onChange {
                    let selected = rsyncUIdata.configurations?.filter { config in
                        selecteduuids.contains(config.id)
                    }
                    if (selected?.count ?? 0) == 1 {
                        if let config = selected {
                            print("selected config FOUND")
                            selectedconfig.config = config[0]
                        }
                    } else {
                        if selecteduuids.count > 1, rsyncUIdata.configurations?.count ?? 0 < selecteduuids.count {
                            print("Multiple selected TASKS")
                        } else {
                            print("selected config NOT FOUND")
                        }
                        selectedconfig.config = nil
                    }
                },
                inwork: $inwork,
                filterstring: $filterstring,
                reload: $reload,
                confirmdelete: $confirmdelete
            )

            // Remember max 10 in one Group
            Group {
                if focusstartestimation { labelstartestimation }
                if focusstartexecution { labelstartexecution }
                if focusfirsttaskinfo { labelfirsttime }
                if focusdeletetask { labeldeletetask }
                if focusshowinfotask { showinfotask }
                if focusaborttask { labelaborttask }
                if focusenabletimer { labelenabletimer }
                if inprogresscountmultipletask.estimateasync { progressviewestimateasync }
            }
        }

        Spacer()

        HStack {
            VStack(alignment: .center) {
                HStack {
                    Button("Estimate") { estimate() }
                        .buttonStyle(PrimaryButtonStyle())
                        .tooltip("Shortcut ⌘E")

                    Button("Execute") { execute() }
                        .buttonStyle(PrimaryButtonStyle())
                        .tooltip("Shortcut ⌘R")

                    Button("DryRun") {
                        if selectedconfig.config != nil &&
                            inprogresscountmultipletask.getestimatedlist()?.count ?? 0 == 0
                        {
                            // execute a dry run task
                            sheetchooser.sheet = .estimateddetailsview
                        } else if selectedconfig.config != nil &&
                            inprogresscountmultipletask.getestimatedlist()?.count ?? 0 == rsyncUIdata.configurations?.count ?? 0
                        {
                            // already estimated, show details on task
                            sheetchooser.sheet = .dryrunalreadyestimated
                        } else {
                            // show summarized dry run
                            sheetchooser.sheet = .dryrun
                        }
                        modaleview = true
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Reset") {
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
            DetailsViewAlreadyEstimated(estimatedlist: inprogresscountmultipletask.getestimatedlist() ?? [],
                                        selectedconfig: selectedconfig.config)
        case .dryrun:
            OutputEstimatedView(selecteduuids: $selecteduuids,
                                execute: $focusstartexecution,
                                estimatedlist: inprogresscountmultipletask.getestimatedlist() ?? [])
        case .estimateddetailsview:
            DetailsView(reload: $reload, selectedconfig: selectedconfig.config)
        case .alltasksview:
            AlltasksView()
        case .firsttime:
            FirsttimeView()
        case .localremoteinfo:
            LocalRemoteInfoView(localdata: $localdata,
                                selectedconfig: selectedconfig.config)
        case .asynctimerison:
            Counter(timervalue: $timervalue, timerisenabled: $timerisenabled.onChange {
                if timerisenabled == true {
                    startasynctimer()
                } else {
                    stopasynctimer()
                }
            })
            .onDisappear(perform: {
                stopasynctimer()
                timervalue = SharedReference.shared.timervalue ?? 600
            })
        }
    }

    var progressviewestimateasync: some View {
        ProgressView()
            .onAppear {
                Task {
                    if selectedconfig.config != nil {
                        print("EstimateOnetaskAsync")
                        let estimateonetaskasync =
                            EstimateOnetaskAsync(configurationsSwiftUI: rsyncUIdata.configurationsfromstore?.configurationData,
                                                 updateinprogresscount: inprogresscountmultipletask,
                                                 hiddenID: selectedconfig.config?.hiddenID)
                        await estimateonetaskasync.execute()
                    } else {
                        print("EstimateAlltasksAsync")
                        let estimatealltasksasync =
                            EstimateAlltasksAsync(profile: rsyncUIdata.configurationsfromstore?.profile,
                                                  configurationsSwiftUI: rsyncUIdata.configurationsfromstore?.configurationData,
                                                  updateinprogresscount: inprogresscountmultipletask,
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
            }
    }

    var showinfotask: some View {
        ProgressView()
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
}

extension TasksView {
    func estimate() {
        if selectedconfig.config != nil {
            let profile = selectedconfig.config?.profile ?? "Default profile"
            if profile != rsyncUIdata.profile {
                selecteduuids.removeAll()
                selectedconfig.config = nil
            }
        }
        inprogresscountmultipletask.resetcounts()
        executedetails.resetcounter()
        inprogresscountmultipletask.startestimateasync()
    }

    func execute() {
        if inprogresscountmultipletask.getuuids().count == rsyncUIdata.configurations?.count ?? 0 {
            print("Execute_All_Estimated tasks")
            // Execute all estimated tasks
            selecteduuids = inprogresscountmultipletask.getuuids()
            estimationstate.updatestate(state: .start)
            executedetails.resetcounter()
            executedetails.setestimatedlist(inprogresscountmultipletask.getestimatedlist())
            showeexecutestimatedview = true
        } else {
            if selectedconfig.config == nil {
                // Execute all tasks, no estimate
                print("Execute_All_NO_Estimated tasks")
                showexecutenoestimateview = true
                showexecutenoestiamteonetask = false
            } else {
                // Execute one task, no estimte
                print("Execute_ONE_NO_Estimated tasks")
                showexecutenoestiamteonetask = true
                showexecutenoestimateview = false
            }
        }
    }

    func reset() {
        inwork = -1
        inprogresscountmultipletask.resetcounts()
        estimationstate.updatestate(state: .start)
        selectedconfig.config = nil
        inprogresscountmultipletask.estimateasync = false
        sheetchooser.sheet = .dryrun
        stopasynctimer()
    }

    func abort() {
        selecteduuids.removeAll()
        estimationstate.updatestate(state: .start)
        inprogresscountmultipletask.resetcounts()
        _ = InterruptProcess()
        inwork = -1
        reload = true
        focusstartestimation = false
        focusstartexecution = false
        stopasynctimer()
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
        SharedReference.shared.workitem?.cancel()
        SharedReference.shared.workitem = nil
    }
}

enum Sheet: String, Identifiable {
    case dryrun, dryrunalreadyestimated, estimateddetailsview, alltasksview, firsttime, localremoteinfo, asynctimerison
    var id: String { rawValue }
}

final class SheetChooser: ObservableObject {
    // Which sheet to present
    // Do not redraw view when changing
    // no @Publised
    var sheet: Sheet = .dryrun
}

final class Selectedconfig: ObservableObject {
    var config: Configuration?
}

// swiftlint:enable line_length
