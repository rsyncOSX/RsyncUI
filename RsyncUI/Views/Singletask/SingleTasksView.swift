//
//  SingleTasksView.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 09/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation
import SwiftUI

struct SingleTasksView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @EnvironmentObject var outputfromrsync: OutputFromRsync

    // Execute estimate and execution
    @StateObject private var singletaskstate = SingleTaskState()
    // Execute singletask, no estimation
    @StateObject private var singletasknowstate = SingletaskNowState()
    // Output from tasks are summarized and reported to the inprogresscountrsyncoutput object
    // Also progress about synchronizing, if estimated first
    @StateObject private var inprogresscountrsyncoutput = InprogressCountRsyncOutput()

    @Binding var selectedconfig: Configuration?
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    // Must be a @State because it is changed
    @State private var executesingletasks: ExecuteSingleTask?
    @State private var executetasknow: ExecuteSingleTaskNow?

    @State private var executestate: SingleTaskWork = .start
    @State private var presentsheetview = false
    // For selecting tasks, the selected index is transformed to the uuid of the task
    @State private var selecteduuids = Set<UUID>()

    // Not used but requiered in parameter
    @State private var inwork = -1
    // Selected row in output
    @State private var valueselectedrow: String = ""
    // If shellout
    @State private var shellout: Bool = false
    // Focus buttons from the menu
    // @State private var focusstartestimation: Bool = false
    @State private var focusstartexecution: Bool = false
    @State private var searchText: String = ""

    // Singletaskview
    @Binding var singletaskview: Bool

    var body: some View {
        ZStack {
            ConfigurationSelected(selectedconfig: $selectedconfig,
                                  selecteduuids: $selecteduuids,
                                  inwork: $inwork,
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
        }

        // When estimated singletaskstate is set to .execute
        if singletaskstate.singletaskstate == .execute {
            SingleTasksEstimatedView(output: inprogresscountrsyncoutput.getoutput() ?? [])
        }

        if shellout { notifyshellout }
        if focusstartexecution { labelshortcutexecute }

        HStack {
            executebutton

            Button("Reset") {
                singletaskview = false
                selectedconfig = nil
            }
            .buttonStyle(PrimaryButtonStyle())

            Spacer()

            // Progressview for execute of estimated task
            if singletaskstate.singletaskstate == .estimated { progressviewexecute }

            Spacer()

            Button("Log") { presentoutput() }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $presentsheetview) { viewoutput }

            Button("Abort") { abort() }
                .buttonStyle(AbortButtonStyle())
        }
        .focusedSceneValue(\.startexecution, $focusstartexecution)
        .task {
            if let config = selectedconfig {
                if (config.executepretask ?? -1) == 1 {
                    shellout = true
                } else {
                    shellout = false
                }
            }
            estimatesingletask()
        }
    }

    // No estimation, just execute task now
    var executebutton: some View {
        Button("Execute") {
            if selectedconfig?.executepretask == 1 {
                executesingletasknow()
            } else {
                executeestimatedsingletask()
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

    var labelshortcutexecute: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusstartexecution = false
                if selectedconfig?.executepretask == 1 {
                    executesingletasknow()
                } else {
                    // Guard statement must be after resetting properties to false
                    executeestimatedsingletask()
                }
            })
    }

    var progressviewexecute: some View {
        ProgressView("" + "…",
                     value: inprogresscountrsyncoutput.getinprogress(),
                     total: Double(inprogresscountrsyncoutput.getmaxcount()))
            .onChange(of: inprogresscountrsyncoutput.getinprogress(), perform: { _ in })
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
        singletaskview = false
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
        guard selecteduuids.count == 1 else { return }
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
