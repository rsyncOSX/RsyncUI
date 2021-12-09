//
//  MultipletasksView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import AlertToast
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
    @State private var focusselecttask: Bool = false
    @State private var focusfirsttaskinfo: Bool = false
    @State private var focusdeletetask: Bool = false

    @State private var searchText: String = ""
    // Singletaskview
    @Binding var singletaskview: Bool
    // Firsttime use of RsyncUI
    @State private var firsttime: Bool = false
    // Which sidebar function
    @Binding var selection: NavigationItem?
    // Delete
    @State private var confirmdeletemenu: Bool = false

    var body: some View {
        ZStack {
            ConfigurationsList(selectedconfig: $selectedconfig,
                               selecteduuids: $selecteduuids,
                               inwork: $inwork,
                               searchText: $searchText,
                               reload: $reload,
                               confirmdeletemenu: $confirmdeletemenu)
            if focusstartestimation { labelshortcutestimation }
            if focusstartexecution { labelshortcutexecute }
            if focusselecttask { labelselecttask }
            if focusfirsttaskinfo { labelfirsttime }
            if focusdeletetask { labeldeletetask }
        }

        HStack {
            Button("Estimate") {
                if selecteduuids.count == 0, selectedconfig != nil {
                    singletaskview = true
                } else {
                    estimationstate.estimateonly = true
                    startestimation()
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("Execute") { startexecution() }
                .buttonStyle(PrimaryButtonStyle())

            Button("Reset") {
                selecteduuids.removeAll()
                reset()
            }
            .buttonStyle(PrimaryButtonStyle())

            Spacer()

            ZStack {
                footer

                if estimationstate.estimationstate == .estimate { progressviewestimation }
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
        .task {
            // Discover if firsttime use, if true present view for firsttime
            firsttime = SharedReference.shared.firsttime
        }
        .sheet(isPresented: $firsttime) {
            FirsttimeView(dismiss: $firsttime,
                          selection: $selection)
        }
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
                if selecteduuids.count == 0, selectedconfig != nil {
                    singletaskview = true
                } else {
                    startestimation()
                }
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
            })
    }

    var labeldeletetask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusdeletetask = false
                confirmdeletemenu = true
            })
    }

    var footer: some View {
        VStack {
            Text("Most recent updated tasks on top of list")
                .foregroundColor(Color.blue)
            Text("Select and slide to left for delete")
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

    func startexecution() {
        setuuidforselectedtask()
        if selecteduuids.count == 0 {
            startestimation()
        } else {
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
}
