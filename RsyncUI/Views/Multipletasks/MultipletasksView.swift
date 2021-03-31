//
//  MultipletasksView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import SwiftUI

struct MultipletasksView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    // The object holds the progressdata for the current estimated task
    // which is executed. Data for progressview.
    @EnvironmentObject var executedetails: InprogressCountExecuteOneTaskDetails
    // Observing shortcuts
    @EnvironmentObject var shortcuts: ShortcutActions

    // These two objects keeps track of the state and collects
    // the estimated values.
    @StateObject private var estimationstate = EstimationState()
    @StateObject private var inprogresscountmultipletask = InprogressCountMultipleTasks()

    @Binding var selectedconfig: Configuration?
    @Binding var reload: Bool

    @State private var presentoutputsheetview = false
    @State private var presentestimatedsheetview = false
    @State private var estimatedlist: [RemoteinfonumbersOnetask]?
    @State private var selecteduuids = Set<UUID>()
    @State private var inwork: Int = -1
    @State private var estimatetask: Estimation?
    // Either selectable configlist or not
    @State private var selectable = true
    // Alert for delete
    @State private var showAlertfordelete = false
    // Alert for execute all
    @State private var showAlertforexecuteall = false

    var body: some View {
        ConfigurationsList(selectedconfig: $selectedconfig.onChange { resetandreload() },
                           selecteduuids: $selecteduuids,
                           inwork: $inwork,
                           selectable: $selectable)

        Spacer()

        // Show progressview for the estimating process
        if estimationstate.estimationstate == .estimate { progressviewestimation }
        // Show label when estimatin is completed.
        if estimationstate.estimationstate != .start { labelcompleted }
        // Shortcuts
        if shortcuts.estimatemultipletasks { labelshortcutestimation }

        HStack {
            Button(NSLocalizedString("All", comment: "Select button")) { executall() }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $showAlertforexecuteall) {
                    ExecuteAlltasksView(selecteduuids: $selecteduuids,
                                        isPresented: $showAlertforexecuteall,
                                        presentestimatedsheetview: $presentestimatedsheetview)
                }

            Button(NSLocalizedString("Select", comment: "Select button")) { select() }
                .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Estimate", comment: "Estimate button")) { startestimation() }
                .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Execute", comment: "Execute button")) { presentexecuteestimatedview() }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $presentestimatedsheetview) {
                    ExecuteEstimatedView(selecteduuids: $selecteduuids,
                                         reload: $reload,
                                         isPresented: $presentestimatedsheetview)
                        .environmentObject(OutputFromMultipleTasks())
                }

            Spacer()

            Button(NSLocalizedString("View", comment: "View button")) { presentoutput() }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $presentoutputsheetview) {
                    OutputEstimatedView(isPresented: $presentoutputsheetview,
                                        estimatedlist: $estimatedlist,
                                        selecteduuids: $selecteduuids)
                }

            Button(NSLocalizedString("Delete", comment: "Delete button")) { delete() }
                .buttonStyle(AbortButtonStyle())
                .sheet(isPresented: $showAlertfordelete) {
                    DeleteConfigurationsView(selecteduuids: $selecteduuids,
                                             isPresented: $showAlertfordelete,
                                             reload: $reload)
                }

            Button(NSLocalizedString("Abort", comment: "Abort button")) { abort() }
                .buttonStyle(AbortButtonStyle())
        }
        .onAppear(perform: {
            shortcuts.enablemultipletask()
        })
        .onDisappear(perform: {
            shortcuts.disablemultipletask()
        })
    }

    var labelshortcutestimation: some View {
        Label(estimationstate.estimationstate.rawValue, systemImage: "play.fill")
            .onAppear(perform: {
                shortcuts.estimatemultipletasks = false
                shortcuts.estimatesingletask = false
                // Guard statement must be after resetting properties to false
                startestimation()
            })
    }

    var progressviewestimation: some View {
        ProgressView("Estimating…", value: inprogresscountmultipletask.getinprogress(),
                     total: Double(inprogresscountmultipletask.getmaxcount()))
            .onChange(of: inprogresscountmultipletask.getinprogress(), perform: { _ in
                inwork = inprogresscountmultipletask.hiddenID
                selecteduuids = inprogresscountmultipletask.getuuids()
            })
            .onAppear(perform: {
                // To set ProgressView spinnig wheel on correct task when estimating
                inwork = inprogresscountmultipletask.hiddenID
            })
            .progressViewStyle(DarkBlueShadowProgressViewStyle())
    }

    var labelcompleted: some View {
        Label(estimationstate.estimationstate.rawValue, systemImage: "play.fill")
            .onChange(of: estimationstate.estimationstate, perform: { _ in
                completed()
            })
    }
}

extension MultipletasksView {
    func executall() {
        executedetails.resetcounter()
        showAlertforexecuteall = true
    }

    func resetandreload() {
        inwork = -1
        inprogresscountmultipletask.resetcounts()
        estimationstate.updatestate(state: .start)
        estimatetask = nil
    }

    func completed() {
        inwork = -1
        selecteduuids = inprogresscountmultipletask.getuuids()
        estimationstate.updatestate(state: .start)
        // Reset and prepare
        executedetails.resetcounter()
        executedetails.setestimatedlist(inprogresscountmultipletask.getestimatedlist())
        estimatetask = nil
    }

    func estimatetasks() {
        estimatetask = Estimation(configurationsSwiftUI: rsyncOSXData.rsyncdata?.configurationData,
                                  estimationstateDelegate: estimationstate,
                                  updateinprogresscount: inprogresscountmultipletask,
                                  uuids: selecteduuids)
        estimatetask?.startestimation()
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

    func startestimation() {
        executedetails.resetcounter()
        // Check if restart or new set of configurations
        if inprogresscountmultipletask.getuuids().count > 0 {
            // print("PROBLEM: (In EstimationView) clearing old uuids not done properly")
            resetandreload()
            selecteduuids.removeAll()
        }
        if selecteduuids.count == 0 {
            setuuidforselectedtask()
        }
        estimationstate.updatestate(state: .estimate)
        estimatetasks()
    }

    func presentoutput() {
        estimatedlist = inprogresscountmultipletask.getestimatedlist()
        // Reset and prepare
        executedetails.resetcounter()
        executedetails.setestimatedlist(inprogresscountmultipletask.getestimatedlist())
        if selecteduuids.count == 0 {
            for i in 0 ..< (estimatedlist?.count ?? 0) {
                if let id = estimatedlist?[i].config?.id {
                    if estimatedlist?[i].selected == 1 {
                        selecteduuids.insert(id)
                    }
                }
            }
        }
        presentoutputsheetview = true
    }

    func presentexecuteestimatedview() {
        if selecteduuids.count == 0 {
            // Try if on task is selected
            setuuidforselectedtask()
        }
        guard selecteduuids.count > 0 else { return }
        presentestimatedsheetview = true
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
           let index = rsyncOSXData.configurations?.firstIndex(of: sel)
        {
            if let id = rsyncOSXData.configurations?[index].id {
                selecteduuids.insert(id)
            }
        }
    }

    func delete() {
        if selecteduuids.count == 0 {
            setuuidforselectedtask()
        }
        guard selecteduuids.count > 0 else { return }
        showAlertfordelete = true
    }
}
