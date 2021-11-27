//
//  MultipletasksView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import AlertToast
import SwiftUI

struct MultipletasksView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @EnvironmentObject var outputfromrsync: OutputFromRsync
    // The object holds the progressdata for the current estimated task
    // which is executed. Data for progressview.
    @EnvironmentObject var executedetails: InprogressCountExecuteOneTaskDetails

    // These two objects keeps track of the state and collects
    // the estimated values.
    @StateObject private var estimationstate = EstimationState()
    @StateObject private var inprogresscountmultipletask = InprogressCountMultipleTasks()

    @Binding var selectedconfig: Configuration?
    @Binding var selectedprofile: String?
    @Binding var reload: Bool
    @Binding var selecteduuids: Set<UUID>
    @Binding var showestimateview: Bool

    @State private var presentoutputsheetview = false
    @State private var presentestimatedsheetview = false
    @State private var inwork: Int = -1
    @State private var estimatetask: Estimation?

    // Focus buttons from the menu
    @State private var focusstartestimation: Bool = false
    @State private var focusstartexecution: Bool = false
    @State private var focusstarttestfortcpconnections: Bool = false
    @State private var searchText: String = ""

    // Singletasks
    // Execute estimate and execution
    @StateObject private var singletaskstate = SingleTaskState()
    // Execute singletask, no estimation
    @StateObject private var singletasknowstate = SingletaskNowState()
    // Output from tasks are summarized and reported to the inprogresscountrsyncoutput object
    // Also progress about synchronizing, if estimated first
    @StateObject private var inprogresscountrsyncoutput = InprogressCountRsyncOutput()
    // Must be a @State because it is changed
    @State private var executesingletasks: ExecuteSingleTask?
    @State private var executetasknow: ExecuteSingleTaskNow?
    @State private var executestate: SingleTaskWork = .start
    @State private var presentsheetview = false
    // If shellout
    @State private var shellout: Bool = false

    var body: some View {
        ZStack {
            ConfigurationsListSelectable(selectedconfig: $selectedconfig.onChange { reset() },
                                         selecteduuids: $selecteduuids,
                                         inwork: $inwork,
                                         searchText: $searchText,
                                         reload: $reload)
            if focusstartestimation { labelshortcutestimation }
            if focusstartexecution { labelshortcutexecute }
            if focusstarttestfortcpconnections { notifyverifyTCPconnections }
        }

        HStack {
            Button("Estimate") {
                estimationstate.estimateonly = true
                startestimation()
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("Execute") { startexecution() }
                .buttonStyle(PrimaryButtonStyle())

            Spacer()

            if estimationstate.estimationstate == .estimate { progressviewestimation }

            Spacer()

            Button("Select") { select() }
                .buttonStyle(PrimaryButtonStyle())

            Button("View") { presentoutput() }
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
        .focusedSceneValue(\.starttestfortcpconnections, $focusstarttestfortcpconnections)
    }

    var progressviewestimation: some View {
        ProgressView("", value: inprogresscountmultipletask.getinprogress(),
                     total: Double(inprogresscountmultipletask.getmaxcount()))
            .onChange(of: inprogresscountmultipletask.getinprogress(), perform: { _ in
                inwork = inprogresscountmultipletask.hiddenID
                selecteduuids = inprogresscountmultipletask.getuuids()
            })
            .onDisappear(perform: {
                estimationcompleted()
            })
            .onAppear(perform: {
                // To set ProgressView spinnig wheel on correct task when estimating
                inwork = inprogresscountmultipletask.hiddenID
            })
            .progressViewStyle(GaugeProgressStyle())
            .frame(width: 25.0, height: 25.0)
            .contentShape(Rectangle())
    }

    var labelshortcutestimation: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusstartestimation = false
                // Guard statement must be after resetting properties to false
                startestimation()
            })
    }

    var labelshortcutexecute: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusstartexecution = false
                // Guard statement must be after resetting properties to false
                startexecution()
            })
    }

    var notifyverifyTCPconnections: some View {
        AlertToast(type: .regular,
                   title: Optional("TCP"), subTitle: Optional(""))
            .task {
                await verifytcp()
            }
    }
}

extension MultipletasksView {
    func reset() {
        inwork = -1
        inprogresscountmultipletask.resetcounts()
        estimationstate.updatestate(state: .start)
        estimatetask = nil
    }

    func estimationcompleted() {
        inwork = -1
        selecteduuids = inprogresscountmultipletask.getuuids()
        estimationstate.updatestate(state: .start)
        // Reset and prepare
        executedetails.resetcounter()
        executedetails.setestimatedlist(inprogresscountmultipletask.getestimatedlist())
        estimatetask = nil

        // Kick of execution
        if selecteduuids.count > 0, estimationstate.estimateonly == false {
            showestimateview = false
        }
        // reset estimateonly
        estimationstate.estimateonly = false
    }

    func estimatetasks() {
        // print("estimatetasks \(Unmanaged.passUnretained(rsyncUIdata).toOpaque())")
        // print("estimatetasks count \(rsyncUIdata.configurations?.count ?? 0)")
        inprogresscountmultipletask.resetcounts()
        estimatetask = Estimation(configurationsSwiftUI: rsyncUIdata.configurationsfromstore?.configurationData,
                                  estimationstateDelegate: estimationstate,
                                  updateinprogresscount: inprogresscountmultipletask,
                                  uuids: selecteduuids,
                                  filter: searchText)
        estimatetask?.startestimation()
    }

    func startestimation() {
        inprogresscountmultipletask.resetcounts()
        executedetails.resetcounter()
        // Check if restart or new set of configurations
        if inprogresscountmultipletask.getuuids().count > 0 {
            reset()
            selecteduuids.removeAll()
        }
        if selecteduuids.count == 0 {
            setuuidforselectedtask()
        }
        estimationstate.updatestate(state: .estimate)
        estimatetasks()
    }

    func abort() {
        selecteduuids.removeAll()
        estimationstate.updatestate(state: .start)
        inprogresscountmultipletask.resetcounts()
        estimatetask?.abort()
        estimatetask = nil
        _ = InterruptProcess()
        inwork = -1
        reload = true
    }

    func presentoutput() {
        // Reset and prepare
        executedetails.resetcounter()
        executedetails.setestimatedlist(inprogresscountmultipletask.getestimatedlist())
        if selecteduuids.count == 0 {
            for i in 0 ..< (inprogresscountmultipletask.getestimatedlist()?.count ?? 0) {
                if let id = inprogresscountmultipletask.getestimatedlist()?[i].config?.id {
                    if inprogresscountmultipletask.getestimatedlist()?[i].selected == 1 {
                        selecteduuids.insert(id)
                    }
                }
            }
        }
        presentoutputsheetview = true
    }

    func startexecution() {
        setuuidforselectedtask()
        if selecteduuids.count == 0 {
            startestimation()
        } else {
            // Estimation is done, kick of execution
            // Or execute selected tasks without estimation
            showestimateview = false
        }
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

    func verifytcp() async {
        if let configurations = rsyncUIdata.configurationsfromstore?.configurationData.getallconfigurations() {
            let tcpconnections = TCPconnections(configurations)
            await tcpconnections.verifyallremoteserverTCPconnections()
            print(tcpconnections.indexBoolremoteserverOff ?? [])
        }
        focusstarttestfortcpconnections = false
    }
}

extension MultipletasksView {
    func completed() {
        if let output = inprogresscountrsyncoutput.getoutput() {
            outputfromrsync.setoutput(output: output)
        }
        reload = true
        selecteduuids.removeAll()
        singletaskstate.updatestate(state: .start)
        singletasknowstate.updatestate(state: .start)
        inprogresscountrsyncoutput.resetcounts()
        executesingletasks = nil
        executetasknow = nil
        singletaskstate.estimateonly = false
    }

    func estimatesingletask() {
        singletaskstate.estimateonly = true
        setuuidforsingletask()
        executeestimatedsingletask()
    }

    // Changed
    func presentrsyncoutput() {
        presentsheetview = true
    }

    func executeestimatedsingletask() {
        switch singletaskstate.singletaskstate {
        case .start:
            executesingletasks = nil
            executetasknow = nil
            singletaskstate.updatestate(state: .estimate)
            executesingletasks = ExecuteSingleTask(uuids: selecteduuids,
                                                   profile: rsyncUIdata.configurationsfromstore?.profile,
                                                   configurationsSwiftUI: rsyncUIdata.configurationsfromstore?.configurationData,
                                                   singletaskstate: singletaskstate,
                                                   updateinprogresscount: inprogresscountrsyncoutput)
            executesingletasks?.estimate()
        case .execute:
            singletaskstate.updatestate(state: .estimated)
            executesingletasks?.execute()
        default:
            return
        }
    }

    // Changed
    func abortsingletask() {
        singletaskstate.updatestate(state: .start)
        singletasknowstate.updatestate(state: .start)
        executesingletasks?.abort()
        executetasknow?.abort()
        executesingletasks = nil
        executetasknow = nil
        inprogresscountrsyncoutput.resetcounts()
        // kill any ongoing processes
        _ = InterruptProcess()
        reload = true
    }

    func resetexecutestate() {
        singletaskstate.updatestate(state: .start)
        singletasknowstate.updatestate(state: .start)
        executesingletasks = nil
        executetasknow = nil
        inprogresscountrsyncoutput.resetcounts()
        if let config = selectedconfig {
            if (config.executepretask ?? -1) == 1 {
                shellout = true
            } else {
                shellout = false
            }
        }
        // kill any ongoing processes
        _ = InterruptProcess()
    }

    func executesingletasknow() {
        executesingletasks = nil
        executetasknow = nil
        setuuidforsingletask()
        guard selecteduuids.count == 1 else { return }
        singletasknowstate.updatestate(state: .execute)
        if let config = selectedconfig {
            if PreandPostTasks(config: config).executepretask || PreandPostTasks(config: config).executeposttask {
                executetasknow =
                    ExecuteSingleTaskNowShellout(uuids: selecteduuids,
                                                 profile: rsyncUIdata.configurationsfromstore?.profile,
                                                 configurationsSwiftUI: rsyncUIdata.configurationsfromstore?.configurationData,
                                                 executetaskstate: singletasknowstate,
                                                 updateinprogresscount: inprogresscountrsyncoutput)
            } else {
                executetasknow =
                    ExecuteSingleTaskNow(uuids: selecteduuids,
                                         profile: rsyncUIdata.configurationsfromstore?.profile,
                                         configurationsSwiftUI: rsyncUIdata.configurationsfromstore?.configurationData,
                                         executetaskstate: singletasknowstate,
                                         updateinprogresscount: inprogresscountrsyncoutput)
            }
        }
    }

    func setuuidforsingletask() {
        selecteduuids.removeAll()
        if let sel = selectedconfig,
           let index = rsyncUIdata.configurations?.firstIndex(of: sel)
        {
            if let id = rsyncUIdata.configurations?[index].id {
                selecteduuids.insert(id)
            }
        }
    }
}
