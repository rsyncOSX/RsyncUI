//
//  MultipletasksView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import SwiftUI

struct MultipletasksView: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
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
    @Binding var selecteduuids: Set<UUID>
    @Binding var showestimateview: Bool

    @State private var presentoutputsheetview = false
    @State private var presentestimatedsheetview = false
    @State private var estimatedlist: [RemoteinfonumbersOnetask]?
    @State private var inwork: Int = -1
    @State private var estimatetask: Estimation?
    // Either selectable configlist or not
    @State private var selectable = true
    // Alert for delete
    @State private var showAlertfordelete = false
    // Alert for execute all
    @State private var showAlertforexecuteall = false
    @State private var confirmdeleteselectedconfigurations = false
    @State private var deleted = false
    // Alert for select tasks
    @State private var notasks: Bool = false

    var body: some View {
        ZStack {
            ConfigurationsList(selectedconfig: $selectedconfig.onChange { resetandreload() },
                               selecteduuids: $selecteduuids,
                               inwork: $inwork,
                               selectable: $selectable)

            if notasks == true {
                AlertToast(type: .regular,
                           title: Optional(NSLocalizedString("Select one or more tasks",
                                                             comment: "settings")), subTitle: Optional(""))
                    .onAppear(perform: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            notasks = false
                        }
                    })
            }

            if deleted == true { notifydeleted }
        }

        // Shortcuts for estimate and execute
        if shortcuts.estimatemultipletasks { labelshortcutestimation }
        if shortcuts.executemultipletasks { labelshortcutexecute }

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

            Button(NSLocalizedString("Execute", comment: "Execute button")) { startexecution() }
                .buttonStyle(PrimaryButtonStyle())

            Spacer()

            if estimationstate.estimationstate == .estimate { progressviewestimation }

            Spacer()

            Button(NSLocalizedString("View", comment: "View button")) { presentoutput() }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $presentoutputsheetview) {
                    OutputEstimatedView(isPresented: $presentoutputsheetview,
                                        estimatedlist: $estimatedlist,
                                        selecteduuids: $selecteduuids)
                }

            Button(NSLocalizedString("Delete", comment: "Delete button")) { preparefordelete() }
                .buttonStyle(AbortButtonStyle())
                .sheet(isPresented: $showAlertfordelete) {
                    ConfirmDeleteConfigurationsView(isPresented: $showAlertfordelete,
                                                    delete: $confirmdeleteselectedconfigurations,
                                                    selecteduuids: $selecteduuids)
                        .onDisappear {
                            delete()
                        }
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
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                shortcuts.estimatemultipletasks = false
                // Guard statement must be after resetting properties to false
                startestimation()
            })
    }

    var labelshortcutexecute: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                shortcuts.executemultipletasks = false
                // Guard statement must be after resetting properties to false
                startexecution()
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
                   title: Optional(NSLocalizedString("Deleted",
                                                     comment: "settings")), subTitle: Optional(""))
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
        estimatetask = Estimation(configurationsSwiftUI: rsyncUIData.rsyncdata?.configurationData,
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
           let index = rsyncUIData.configurations?.firstIndex(of: sel)
        {
            if let id = rsyncUIData.configurations?[index].id {
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
            UpdateConfigurations(profile: rsyncUIData.rsyncdata?.profile,
                                 configurations: rsyncUIData.rsyncdata?.configurationData.getallconfigurations())
        deleteconfigurations.deleteconfigurations(uuids: selecteduuids)
        selecteduuids.removeAll()
        reload = true
        deleted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            deleted = false
        }
    }
}
