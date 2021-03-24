//
//  SingleTasksView.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 09/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import Foundation
import SwiftUI

struct SingleTasksView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @EnvironmentObject var outputfromrsync: OutputFromRsync

    // Execute estimate and execution
    @StateObject private var singletaskstate = SingleTaskState()
    // Execute singletask, no estimation
    @StateObject private var singletasknowstate = SingletaskNowState()
    // Output from tasks are summarized and reported to the inprogresscountrsyncoutput object
    // Also progress about synchronizing, if estimated first
    @StateObject private var inprogresscountrsyncoutput = InprogressCountRsyncOutput()

    @State private var executesingletasks: ExecuteSingleTask?
    @State private var executetasknow: ExecuteSingleTaskNow?
    @State private var selectedconfig: Configuration?
    @State private var executestate: SingleTaskWork = .start
    @State private var presentsheetview = false
    @State private var output: [Outputrecord]?
    // For selecting tasks, the selected index is transformed to the uuid of the task
    @State private var selecteduuids = Set<UUID>()
    @Binding var reload: Bool

    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false

    var body: some View {
        ConfigurationsList(selectedconfig: $selectedconfig.onChange { resetexecutestate() },
                           selecteduuids: $selecteduuids,
                           inwork: $inwork,
                           selectable: $selectable)

        // Estimate singletask or Execute task now
        if singletasknowstate.executetasknowstate == .execute { ImageZstackProgressview() }
        if singletaskstate.singletaskstate == .estimate { ImageZstackProgressview() }
        // Execute singletask
        if singletaskstate.singletaskstate == .estimated { progressviewexecute }

        HStack {
            if singletaskstate.singletaskstate != .start { labelestimate }

            if singletasknowstate.executetasknowstate != .start { labelexecutenow }

            Spacer()
        }

        HStack {
            HStack {
                estimateandexecute

                executenow
            }

            Spacer()

            Button(NSLocalizedString("View", comment: "View button")) { presentoutput() }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $presentsheetview) { viewoutput }

            Button(NSLocalizedString("Abort", comment: "Abort button")) { abort() }
                .buttonStyle(AbortButtonStyle())
        }
    }

    // Estimate and the execute.
    var estimateandexecute: some View {
        if singletaskstate.singletaskstate == .start {
            // Estimate
            return Button(NSLocalizedString("Estimate", comment: "Estimate button")) { initsingletask() }
                .buttonStyle(PrimaryButtonStyle())
        } else {
            // Execute estimated
            return Button(NSLocalizedString("Execute", comment: "Execute button")) { singletask() }
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    // No estiamtion, just execute task now
    var executenow: some View {
        return Button(NSLocalizedString("Now", comment: "Now button")) { singletasknow() }
            .buttonStyle(PrimaryButtonStyle())
    }

    var progressviewexecute: some View {
        ProgressView(NSLocalizedString("Executing tasks", comment: "Execute tasks") + "…",
                     value: inprogresscountrsyncoutput.getinprogress(),
                     total: Double(inprogresscountrsyncoutput.getmaxcount()))
            .onChange(of: inprogresscountrsyncoutput.getinprogress(), perform: { _ in
            })
    }

    // When status == .completed execute completed for reload
    var labelestimate: some View {
        Label(singletaskstate.singletaskstate.rawValue, systemImage: "play.fill")
            .onChange(of: singletaskstate.singletaskstate, perform: { _ in
                if singletaskstate.singletaskstate == .completed { completed() }
            })
    }

    // When status == .completed execute completed for reload
    var labelexecutenow: some View {
        Label(singletasknowstate.executetasknowstate.rawValue, systemImage: "play.fill")
            .onChange(of: singletasknowstate.executetasknowstate, perform: { _ in
                if singletasknowstate.executetasknowstate == .completed { completed() }
            })
    }

    // Output
    var viewoutput: some View {
        OutputRsyncView(config: $selectedconfig,
                        isPresented: $presentsheetview,
                        output: $output)
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
    }

    func initsingletask() {
        setuuidforsingletask()
        singletask()
    }

    func presentoutput() {
        // Output from realrun
        output = outputfromrsync.getoutput()
        // Output from estimation run
        if output == nil {
            output = inprogresscountrsyncoutput.getoutput()
        }
        presentsheetview = true
    }

    func singletask() {
        guard selecteduuids.count == 1 else { return }
        switch singletaskstate.singletaskstate {
        case .start:
            executesingletasks = nil
            executetasknow = nil
            singletaskstate.updatestate(state: .estimate)
            executesingletasks = ExecuteSingleTask(uuids: selecteduuids,
                                                   profile: rsyncOSXData.rsyncdata?.profile,
                                                   configurationsSwiftUI: rsyncOSXData.rsyncdata?.configurationData,
                                                   schedulesSwiftUI: rsyncOSXData.rsyncdata?.scheduleData,
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
        // kill any ongoing processes
        _ = InterruptProcess()
    }

    func singletasknow() {
        executesingletasks = nil
        executetasknow = nil
        setuuidforsingletask()
        guard selecteduuids.count == 1 else { return }
        singletasknowstate.updatestate(state: .execute)
        executetasknow = ExecuteSingleTaskNow(uuids: selecteduuids,
                                              profile: rsyncOSXData.rsyncdata?.profile,
                                              configurationsSwiftUI: rsyncOSXData.rsyncdata?.configurationData,
                                              schedulesSwiftUI: rsyncOSXData.rsyncdata?.scheduleData,
                                              executetaskstate: singletasknowstate,
                                              updateinprogresscount: inprogresscountrsyncoutput)
    }

    func setuuidforsingletask() {
        selecteduuids.removeAll()
        if let sel = selectedconfig,
           let index = rsyncOSXData.configurations?.firstIndex(of: sel)
        {
            if let id = rsyncOSXData.configurations?[index].id {
                selecteduuids.insert(id)
            }
        }
    }
}
