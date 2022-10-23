//
//  MultipletasksView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//
// swiftlint:disable line_length

import Network
import SwiftUI

struct MultipletasksView: View {
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
    @Binding var showestimateview: Bool
    @Binding var showcompleted: Bool

    @State private var presentoutputsheetview = false
    @State private var presentestimatedsheetview = false
    @State private var inwork: Int = -1

    // Focus buttons from the menu
    @State private var focusstartestimation: Bool = false
    @State private var focusstartexecution: Bool = false
    @State private var focusselecttask: Bool = false
    @State private var focusfirsttaskinfo: Bool = false
    @State private var focusdeletetask: Bool = false
    @State private var focusshowinfotask: Bool = false

    @State private var searchText: String = ""
    // Singletaskview
    @Binding var singletaskview: Bool
    // Firsttime use of RsyncUI
    @State private var firsttime: Bool = false
    // Which sidebar function
    @Binding var selection: NavigationItem?
    // Delete
    @State private var confirmdeletemenu: Bool = false
    // Estimate ahead of execute task
    @State private var alwaysestimate: Bool = SharedReference.shared.alwaysestimate
    // Local data for present local and remote info about task
    @State private var localdata: [String] = []
    @State private var progressviewshowinfo = false
    // Modale view
    @State private var modaleview = false

    var body: some View {
        ZStack {
            ConfigurationsList(selectedconfig: $selectedconfig,
                               selecteduuids: $selecteduuids,
                               inwork: $inwork,
                               searchText: $searchText,
                               reload: $reload,
                               confirmdelete: $confirmdeletemenu)
            if focusstartestimation { progressviewestimateasync }
            if focusstartexecution { labelshortcutexecute }
            if focusselecttask { labelselecttask }
            if focusfirsttaskinfo { labelfirsttime }
            if focusdeletetask { labeldeletetask }
            if focusshowinfotask { labelshowinfotask }
        }

        HStack {
            VStack(alignment: .center) {
                // ToggleViewDefault(NSLocalizedString("Estimate", comment: ""), $alwaysestimate)

                HStack {
                    Button("Estimate") {
                        inprogresscountmultipletask.resetcounts()
                        executedetails.resetcounter()
                        inprogresscountmultipletask.startestimateasync()
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Execute") {
                        selecteduuids = inprogresscountmultipletask.getuuids()
                        guard selecteduuids.count > 0 else {
                            inprogresscountmultipletask.startasyncexecutealltasksnoestimation()
                            return
                        }
                        estimationstate.updatestate(state: .start)
                        executedetails.resetcounter()
                        executedetails.setestimatedlist(inprogresscountmultipletask.getestimatedlist())
                        showestimateview = false
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Reset") {
                        selecteduuids.removeAll()
                        reset()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }

            Spacer()

            ZStack {
                if estimationstate.estimationstate != .estimate { footer }
                if progressviewshowinfo {
                    RotatingDotsIndicatorView()
                        .frame(width: 25.0, height: 25.0)
                        .foregroundColor(.blue)
                }
                if inprogresscountmultipletask.estimateasync { progressviewestimateasync }
                if inprogresscountmultipletask.executeasyncnoestimation { progressviewexecuteasync }
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

    var progressviewestimateasync: some View {
        RotatingDotsIndicatorView()
            .frame(width: 25.0, height: 25.0)
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
                            EstimateAlltasksAsync(configurationsSwiftUI: rsyncUIdata.configurationsfromstore?.configurationData,
                                                  updateinprogresscount: inprogresscountmultipletask,
                                                  uuids: selecteduuids,
                                                  filter: searchText)
                        await estimatealltasksasync.startestimation()
                    }
                }
            }
            .onDisappear {
                presentoutputsheetview = true
            }
    }

    var progressviewexecuteasync: some View {
        RotatingDotsIndicatorView()
            .frame(width: 25.0, height: 25.0)
            .foregroundColor(.blue)
            .onAppear {
                Task {
                    if selectedconfig != nil && selecteduuids.count == 0 {
                        let executeonetaskasync =
                            ExecuteOnetaskAsync(configurationsSwiftUI: rsyncUIdata.configurationsfromstore?.configurationData,
                                                updateinprogresscount: inprogresscountmultipletask,
                                                hiddenID: selectedconfig?.hiddenID)
                        await executeonetaskasync.execute()

                    } else {
                        let executealltasksasync =
                            ExecuteAlltasksAsync(configurationsSwiftUI: rsyncUIdata.configurationsfromstore?.configurationData,
                                                 updateinprogresscount: inprogresscountmultipletask,
                                                 uuids: selecteduuids,
                                                 filter: searchText)
                        await executealltasksasync.startestimation()
                    }
                }
            }
            .onDisappear {
                showcompleted = true
            }
    }

    var labelshortcutexecute: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusstartexecution = false
                startexecution()
            })
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
                let tasklocalinfo = RsyncAsync(arguments: argumentslocalinfo, config: selectedconfig,
                                               processtermination: processtermination)
                Task {
                    await tasklocalinfo.executeProcess()
                }
                focusshowinfotask = false
            })
    }

    var footer: some View {
        Text("Most recent updated tasks on top of list")
            .foregroundColor(Color.blue)
    }
}

extension MultipletasksView {
    func reset() {
        inwork = -1
        inprogresscountmultipletask.resetcounts()
        estimationstate.updatestate(state: .start)
        alwaysestimate = SharedReference.shared.alwaysestimate
    }

    func abort() {
        selecteduuids.removeAll()
        estimationstate.updatestate(state: .start)
        inprogresscountmultipletask.resetcounts()
        _ = InterruptProcess()
        inwork = -1
        reload = true
    }

    func startexecution() {
        showestimateview = false
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

    func setuuidforselectedtask() {
        if let sel = selectedconfig,
           let index = rsyncUIdata.configurations?.firstIndex(of: sel)
        {
            if let id = rsyncUIdata.configurations?[index].id {
                selecteduuids.insert(id)
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
