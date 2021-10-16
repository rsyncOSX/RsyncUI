//
//  SingleTasksView.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 09/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import AlertToast
import Foundation
import SwiftUI

struct SingleTasksView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @EnvironmentObject var outputfromrsync: OutputFromRsync

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

    @State private var selectedconfig: Configuration?
    @State private var executestate: SingleTaskWork = .start
    @State private var presentsheetview = false
    // For selecting tasks, the selected index is transformed to the uuid of the task
    @State private var selecteduuids = Set<UUID>()
    @Binding var reload: Bool
    @Binding var selectedprofile: String?

    // Not used but requiered in parameter
    @State private var inwork = -1
    // Selected row in output
    @State private var valueselectedrow: String = ""
    // If shellout
    @State private var shellout: Bool = false
    // Alert for select tasks
    @State private var notasks: Bool = false
    // Focus buttons from the menu
    @State private var focusstartestimation: Bool = false
    @State private var focusstartexecution: Bool = false
    @State private var searchText: String = ""

    var body: some View {
        ZStack {
            ConfigurationsListNonSelectable(selectedconfig: $selectedconfig.onChange { resetexecutestate() },
                                            selecteduuids: $selecteduuids,
                                            inwork: $inwork,
                                            searchText: $searchText,
                                            reload: $reload)

            // Estimate singletask or Execute task now
            if singletasknowstate.executetasknowstate == .execute {
                RotatingDotsIndicatorView()
                    .frame(width: 50.0, height: 50.0)
                    .foregroundColor(.red)
            }

            if singletaskstate.singletaskstate == .estimate {
                RotatingDotsIndicatorView()
                    .frame(width: 50.0, height: 50.0)
                    .foregroundColor(.red)
            }

            if notasks == true {
                AlertToast(type: .regular, title: Optional("Select a task"), subTitle: Optional(""))
                    .onAppear(perform: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            notasks = false
                        }
                    })
            }
        }

        // When estimated singletaskstate is set to .execute
        if singletaskstate.singletaskstate == .execute {
            SingleTasksEstimatedView(output: inprogresscountrsyncoutput.getoutput() ?? [])
        }

        if shellout { notifyshellout }
        if focusstartestimation { labelshortcutestimation }
        if focusstartexecution { labelshortcutexecute }

        HStack {
            HStack {
                // Estimate
                Button("Estimate") { estimatesingletask() }
                    .buttonStyle(PrimaryButtonStyle())

                executebutton
            }

            Spacer()

            // Progressview for execute of estimated task
            if singletaskstate.singletaskstate == .estimated { progressviewexecute }

            Spacer()

            Button("View") { presentoutput() }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $presentsheetview) { viewoutput }

            Button("Abort") { abort() }
                .buttonStyle(AbortButtonStyle())
        }
        .focusedSceneValue(\.startestimation, $focusstartestimation)
        .focusedSceneValue(\.startexecution, $focusstartexecution)
        .onAppear(perform: {
            if selectedprofile == nil {
                selectedprofile = SharedReference.shared.defaultprofile
            }
        })
    }

    // No estimation, just execute task now
    var executebutton: some View {
        Button("Execute") {
            if singletaskstate.estimateonly == true {
                executeestimatedsingletask()
            } else {
                executesingletasknow()
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .onChange(of: singletasknowstate.executetasknowstate, perform: { _ in
            if singletasknowstate.executetasknowstate == .completed {
                completed()
            }
        })
        .onChange(of: singletaskstate.singletaskstate, perform: { _ in
            if singletaskstate.singletaskstate == .completed {
                completed()
            }
        })
    }

    // Shortcuts
    var labelshortcutestimation: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusstartestimation = false
                // Guard statement must be after resetting properties to false
                estimatesingletask()
            })
    }

    var labelshortcutexecute: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusstartexecution = false
                // Guard statement must be after resetting properties to false
                executeestimatedsingletask()
            })
    }

    var progressviewexecute: some View {
        ProgressView("" + "…",
                     value: inprogresscountrsyncoutput.getinprogress(),
                     total: Double(inprogresscountrsyncoutput.getmaxcount()))
            .onChange(of: inprogresscountrsyncoutput.getinprogress(), perform: { _ in
            })
            .progressViewStyle(GaugeProgressStyle())
            .frame(width: 25.0, height: 25.0)
            .contentShape(Rectangle())
    }

    // Output
    var viewoutput: some View {
        if singletaskstate.singletaskstate == .start ||
            singletaskstate.singletaskstate == .estimate ||
            singletaskstate.singletaskstate == .completed
        {
            // real run output
            return OutputRsyncView(isPresented: $presentsheetview,
                                   valueselectedrow: $valueselectedrow,
                                   output: outputfromrsync.getoutput() ?? [])
        } else {
            // estimated run output
            return OutputRsyncView(isPresented: $presentsheetview,
                                   valueselectedrow: $valueselectedrow,
                                   output: inprogresscountrsyncoutput.getoutput() ?? [])
        }
    }

    var notifyshellout: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text("Pre and post task")
                .font(.title3)
                .foregroundColor(Color.accentColor)
        }
        .frame(width: 200, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
    }
}

extension SingleTasksView {
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

    func presentoutput() {
        presentsheetview = true
    }

    func executeestimatedsingletask() {
        guard selecteduuids.count == 1 else {
            notasks = true
            return
        }
        switch singletaskstate.singletaskstate {
        case .start:
            executesingletasks = nil
            executetasknow = nil
            singletaskstate.updatestate(state: .estimate)
            executesingletasks = ExecuteSingleTask(uuids: selecteduuids,
                                                   profile: rsyncUIdata.rsyncdata?.profile,
                                                   configurationsSwiftUI: rsyncUIdata.rsyncdata?.configurationData,
                                                   // schedulesSwiftUI: rsyncUIdata.rsyncdata?.scheduleData,
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

    func abort() {
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
        guard selecteduuids.count == 1 else {
            notasks = true
            return
        }
        singletasknowstate.updatestate(state: .execute)
        if let config = selectedconfig {
            if PreandPostTasks(config: config).executepretask || PreandPostTasks(config: config).executeposttask {
                executetasknow =
                    ExecuteSingleTaskNowShellout(uuids: selecteduuids,
                                                 profile: rsyncUIdata.rsyncdata?.profile,
                                                 configurationsSwiftUI: rsyncUIdata.rsyncdata?.configurationData,
                                                 // TODO: fix schedules
                                                 // schedulesSwiftUI: SchedulesSwiftUI?,
                                                 // schedulesSwiftUI: rsyncUIdata.rsyncdata?.scheduleData,
                                                 executetaskstate: singletasknowstate,
                                                 updateinprogresscount: inprogresscountrsyncoutput)
            } else {
                executetasknow =
                    ExecuteSingleTaskNow(uuids: selecteduuids,
                                         profile: rsyncUIdata.rsyncdata?.profile,
                                         configurationsSwiftUI: rsyncUIdata.rsyncdata?.configurationData,
                                         // TODO: fix schedules
                                         // schedulesSwiftUI: SchedulesSwiftUI?,
                                         // schedulesSwiftUI: rsyncUIdata.rsyncdata?.scheduleData,
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
