//
//  TasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/01/2021.
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

    @Binding var selectedconfig: Configuration?
    @Binding var reload: Bool
    @Binding var selecteduuids: Set<UUID>
    @Binding var showeexecutestimatedview: Bool
    @Binding var showcompleted: Bool
    @Binding var showexecutenoestimateview: Bool
    @Binding var showexecutenoestiamteonetask: Bool

    @State private var presentoutputsheetview = false
    @State private var inwork: Int = -1

    // Focus buttons from the menu
    @State private var focusstartestimation: Bool = false
    @State private var focusstartexecution: Bool = false
    @State private var focusselecttask: Bool = false
    @State private var focusfirsttaskinfo: Bool = false
    @State private var focusdeletetask: Bool = false
    @State private var focusshowinfotask: Bool = false
    @State private var focusaborttask: Bool = false

    @State private var searchText: String = ""
    // Firsttime use of RsyncUI
    @State private var firsttime: Bool = false
    // Which sidebar function
    @Binding var selection: NavigationItem?
    // Delete
    @State private var confirmdeletemenu: Bool = false
    // Local data for present local and remote info about task
    @State private var localdata: [String] = []
    // For get local and remote info one task
    @State private var progressviewshowinfo = false
    // Modale view
    @State private var modaleview = false
    // Dryrun view
    @State private var dryrunview = false

    var body: some View {
        ZStack {
            ListofTasksProgress(selectedconfig: $selectedconfig.onChange {
                guard selectedconfig != nil else { return }
                if alltasksestimated { dryrunview = true }
            },
            selecteduuids: $selecteduuids,
            inwork: $inwork,
            searchText: $searchText,
            reload: $reload,
            confirmdelete: $confirmdeletemenu)

            // Remember max 10 in one Group
            Group {
                if focusstartestimation { labelstartestimation }
                if focusstartexecution { labelstartexecution }
                if focusselecttask { labelselecttask }
                if focusfirsttaskinfo { labelfirsttime }
                if focusdeletetask { labeldeletetask }
                if focusshowinfotask { labelshowinfotask }
                if focusaborttask { labelaborttask }
                if inprogresscountmultipletask.estimateasync { progressviewestimateasync }
                if progressviewshowinfo {
                    RotatingDotsIndicatorView()
                        .frame(width: 50.0, height: 50.0)
                        .foregroundColor(.blue)
                }
            }
        }

        HStack {
            VStack(alignment: .center) {
                HStack {
                    Button("Estimate") { estimate() }
                        .buttonStyle(PrimaryButtonStyle())

                    Button("Execute") { execute() }
                        .buttonStyle(PrimaryButtonStyle())

                    Button("DryRun") {
                        guard selectedconfig != nil else { return }
                        dryrunview = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .sheet(isPresented: $dryrunview) {
                        if inprogresscountmultipletask.getestimatedlist()?.count ?? 0 > 0 {
                            DetailsViewAlreadyEstimated(selectedconfig: $selectedconfig,
                                                        reload: $reload,
                                                        isPresented: $dryrunview,
                                                        estimatedlist: inprogresscountmultipletask.getestimatedlist() ?? [])
                                .onDisappear(perform: {
                                    selectedconfig = nil
                                })

                        } else {
                            DetailsView(selectedconfig: $selectedconfig,
                                        reload: $reload,
                                        isPresented: $dryrunview)
                        }
                    }

                    Button("Reset") {
                        selecteduuids.removeAll()
                        reset()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }

            Spacer()

            ZStack {
                VStack {
                    if alltasksestimated { alltasksestimatedtext }
                    if estimationstate.estimationstate != .estimate { footer }
                }
            }

            Spacer()

            Button("Log") { presentoutputsheetview = true }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $presentoutputsheetview) {
                    OutputEstimatedView(isPresented: $presentoutputsheetview,
                                        selecteduuids: $selecteduuids,
                                        estimatedlist: inprogresscountmultipletask.getestimatedlist() ?? [])
                }

            Button("Abort") { abort() }
                .buttonStyle(AbortButtonStyle())
        }
        .focusedSceneValue(\.startestimation, $focusstartestimation)
        .focusedSceneValue(\.startexecution, $focusstartexecution)
        .focusedSceneValue(\.selecttask, $focusselecttask)
        .focusedSceneValue(\.firsttaskinfo, $focusfirsttaskinfo)
        .focusedSceneValue(\.deletetask, $focusdeletetask)
        .focusedSceneValue(\.showinfotask, $focusshowinfotask)
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .task {
            // Discover if firsttime use, if true present view for firsttime
            firsttime = SharedReference.shared.firsttime
            modaleview = firsttime
        }
        .sheet(isPresented: $modaleview) {
            if firsttime {
                FirsttimeView(dismiss: $modaleview,
                              selection: $selection)
            } else {
                LocalRemoteInfoView(dismiss: $modaleview,
                                    localdata: $localdata,
                                    selectedconfig: $selectedconfig)
            }
        }
    }

    var alltasksestimated: Bool {
        return inprogresscountmultipletask.getestimatedlist()?.count == rsyncUIdata.configurations?.count
    }

    var alltasksestimatedtext: some View {
        Text("All tasks are estimated - select task to view details or Reset for reset")
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

    var progressviewestimateasync: some View {
        RotatingDotsIndicatorView()
            .frame(width: 50.0, height: 50.0)
            .foregroundColor(.blue)
            .onAppear {
                Task {
                    if selectedconfig != nil && selecteduuids.count == 0 {
                        let estimateonetaskasync =
                            EstimateOnetaskAsync(configurationsSwiftUI: rsyncUIdata.configurationsfromstore?.configurationData,
                                                 updateinprogresscount: inprogresscountmultipletask,
                                                 hiddenID: selectedconfig?.hiddenID)
                        await estimateonetaskasync.execute()
                    } else {
                        let estimatealltasksasync =
                            EstimateAlltasksAsync(profile: rsyncUIdata.configurationsfromstore?.profile,
                                                  configurationsSwiftUI: rsyncUIdata.configurationsfromstore?.configurationData,
                                                  updateinprogresscount: inprogresscountmultipletask,
                                                  uuids: selecteduuids,
                                                  filter: searchText)
                        await estimatealltasksasync.startexecution()
                    }
                }
            }
            .onDisappear {
                presentoutputsheetview = true
                focusstartestimation = false
            }
    }

    var labelselecttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusselecttask = false
                select()
            })
    }

    var labelfirsttime: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusfirsttaskinfo = false
                firsttime = true
                modaleview = true
            })
    }

    var labeldeletetask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusdeletetask = false
                confirmdeletemenu = true
            })
    }

    var labelshowinfotask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                progressviewshowinfo = true
                let argumentslocalinfo = ArgumentsLocalcatalogInfo(config: selectedconfig)
                    .argumentslocalcataloginfo(dryRun: true, forDisplay: false)
                guard argumentslocalinfo != nil else {
                    focusshowinfotask = false
                    progressviewshowinfo = false
                    return
                }
                let tasklocalinfo = RsyncAsync(arguments: argumentslocalinfo,
                                               processtermination: processtermination)
                Task {
                    await tasklocalinfo.executeProcess()
                }
                focusshowinfotask = false
            })
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }

    var footer: some View {
        Text("Most recent updated tasks on top of list")
            .foregroundColor(Color.blue)
    }
}

extension TasksView {
    func estimate() {
        inprogresscountmultipletask.resetcounts()
        executedetails.resetcounter()
        inprogresscountmultipletask.startestimateasync()
    }

    func execute() {
        selecteduuids = inprogresscountmultipletask.getuuids()
        guard selecteduuids.count > 0 else {
            if selectedconfig == nil {
                // Execute all tasks, no estimate
                showexecutenoestimateview = true
                showexecutenoestiamteonetask = false
            } else {
                // Execute one task, no estimte
                showexecutenoestiamteonetask = true
                showexecutenoestimateview = false
            }
            return
        }
        // Execute all estimated tasks.
        estimationstate.updatestate(state: .start)
        executedetails.resetcounter()
        executedetails.setestimatedlist(inprogresscountmultipletask.getestimatedlist())
        showeexecutestimatedview = true
    }

    func reset() {
        inwork = -1
        inprogresscountmultipletask.resetcounts()
        estimationstate.updatestate(state: .start)
        selectedconfig = nil
        progressviewshowinfo = false
        inprogresscountmultipletask.estimateasync = false
    }

    func abort() {
        selecteduuids.removeAll()
        estimationstate.updatestate(state: .start)
        inprogresscountmultipletask.resetcounts()
        _ = InterruptProcess()
        inwork = -1
        reload = true
        progressviewshowinfo = false
        focusstartestimation = false
        focusstartexecution = false
    }

    func select() {
        if let selectedconfig = selectedconfig {
            if selecteduuids.contains(selectedconfig.id) {
                selecteduuids.remove(selectedconfig.id)
            } else {
                selecteduuids.insert(selectedconfig.id)
            }
        }
    }

    // For info about one task
    func processtermination(data: [String]?) {
        localdata = data ?? []
        modaleview = true
        progressviewshowinfo = false
    }
}
