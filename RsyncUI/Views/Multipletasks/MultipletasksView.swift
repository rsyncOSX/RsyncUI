//
//  MultipletasksView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import SwiftUI

struct MultipletasksView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
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
    // Alert for delete
    @State private var showAlertfordelete = false
    // Alert for execute all
    @State private var showAlertforexecuteall = false
    @State private var confirmdeleteselectedconfigurations = false
    @State private var deleted = false
    // Alert for select tasks
    @State private var notasks: Bool = false
    // Focus buttons from the menu
    @State private var focusstartestimation: Bool = false
    @State private var focusstartexecution: Bool = false
    @State private var searchText: String = ""

    // Either selectable configlist or not
    let selectable = true

    var body: some View {
        ZStack {
            ConfigurationsList(selectedconfig: $selectedconfig.onChange { reset() },
                               selecteduuids: $selecteduuids,
                               inwork: $inwork,
                               searchText: $searchText,
                               selectable: selectable)
            if notasks == true { notifyselecttask }
            if deleted == true { notifydeleted }
            if focusstartestimation { labelshortcutestimation }
            if focusstartexecution { labelshortcutexecute }
        }

        HStack {
            Button("All") { executall() }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $showAlertforexecuteall) {
                    ExecuteAlltasksView(selecteduuids: $selecteduuids,
                                        isPresented: $showAlertforexecuteall,
                                        presentestimatedsheetview: $presentestimatedsheetview)
                }

            Button("Select") { select() }
                .buttonStyle(PrimaryButtonStyle())

            Button("Estimate") { startestimation() }
                .buttonStyle(PrimaryButtonStyle())

            Button("Execute") { startexecution() }
                .buttonStyle(PrimaryButtonStyle())

            Spacer()

            if estimationstate.estimationstate == .estimate { progressviewestimation }

            Spacer()

            Button("View") { presentoutput() }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $presentoutputsheetview) {
                    OutputEstimatedView(isPresented: $presentoutputsheetview,
                                        selecteduuids: $selecteduuids,
                                        estimatedlist: inprogresscountmultipletask.getestimatedlist() ?? [])
                }

            Button("Delete") { preparefordelete() }
                .buttonStyle(AbortButtonStyle())
                .sheet(isPresented: $showAlertfordelete) {
                    ConfirmDeleteConfigurationsView(isPresented: $showAlertfordelete,
                                                    delete: $confirmdeleteselectedconfigurations,
                                                    selecteduuids: $selecteduuids)
                        .onDisappear {
                            delete()
                        }
                }

            Button("Abort") { abort() }
                .buttonStyle(AbortButtonStyle())
        }
        .focusedSceneValue(\.startestimation, $focusstartestimation)
        .focusedSceneValue(\.startexecution, $focusstartexecution)
        .onAppear(perform: {
            if selectedprofile == nil {
                selectedprofile = "Default profile"
            }
        })
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
            .frame(width: 50.0, height: 50.0)
            .contentShape(Rectangle())
    }

    var notifydeleted: some View {
        AlertToast(type: .complete(Color.green),
                   title: Optional("Deleted"), subTitle: Optional(""))
            .onAppear(perform: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    deleted = false
                }
            })
    }

    var notifyselecttask: some View {
        AlertToast(type: .regular,
                   title: Optional("Select one or more tasks"), subTitle: Optional(""))
            .onAppear(perform: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    notasks = false
                }
            })
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
}

extension MultipletasksView {
    func executall() {
        executedetails.resetcounter()
        showAlertforexecuteall = true
    }

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
    }

    func estimatetasks() {
        print("estimatetasks \(Unmanaged.passUnretained(rsyncUIdata).toOpaque())")
        print("estimatetasks count \(rsyncUIdata.configurations?.count ?? 0)")
        inprogresscountmultipletask.resetcounts()
        estimatetask = Estimation(configurationsSwiftUI: rsyncUIdata.rsyncdata?.configurationData,
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
        if selecteduuids.count == 0 {
            // Try if on task is selected
            setuuidforselectedtask()
        }
        guard selecteduuids.count > 0 else {
            notasks = true
            return
        }
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

    func preparefordelete() {
        if selecteduuids.count == 0 {
            setuuidforselectedtask()
        }
        guard selecteduuids.count > 0 else { return }
        showAlertfordelete = true
    }

    func delete() {
        guard confirmdeleteselectedconfigurations == true else {
            selecteduuids.removeAll()
            return
        }
        let deleteconfigurations =
            UpdateConfigurations(profile: rsyncUIdata.rsyncdata?.profile,
                                 configurations: rsyncUIdata.rsyncdata?.configurationData.getallconfigurations())
        deleteconfigurations.deleteconfigurations(uuids: selecteduuids)
        selecteduuids.removeAll()
        reload = true
        deleted = true
    }
}

/*
 TODO: when change profile reset stateobjects.
 */
