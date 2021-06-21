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
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @EnvironmentObject var outputfromrsync: OutputFromRsync
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

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

    let selectable = false

    var body: some View {
        ZStack {
            ConfigurationsList(selectedconfig: $selectedconfig.onChange { resetexecutestate() },
                               selecteduuids: $selecteduuids,
                               inwork: $inwork,
                               selectable: selectable)

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
                AlertToast(type: .regular, title: Optional(NSLocalizedString("Select a task",
                                                                             comment: "settings")), subTitle: Optional(""))
                    .onAppear(perform: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            notasks = false
                        }
                    })
            }
        }

        if shellout { notifyshellout }
        if focusstartestimation { labelshortcutestimation }
        if focusstartexecution { labelshortcutexecute }

        HStack {
            HStack {
                estimateandexecute

                executenow
            }

            Spacer()

            // Progressview for execute of estimated task
            if singletaskstate.singletaskstate == .estimated { progressviewexecute }

            Spacer()

            Button(NSLocalizedString("View", comment: "View button")) { presentoutput() }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $presentsheetview) { viewoutput }

            Button(NSLocalizedString("Abort", comment: "Abort button")) { abort() }
                .buttonStyle(AbortButtonStyle())
        }
        .padding()
        .onAppear(perform: {
            if selectedprofile == nil {
                selectedprofile = NSLocalizedString("Default profile", comment: "default profile")
            }
        })
    }

    // Estimate and the execute.
    var estimateandexecute: some View {
        HStack {
            if singletaskstate.singletaskstate == .start ||
                singletaskstate.singletaskstate == .estimate ||
                singletaskstate.singletaskstate == .completed
            {
                // Estimate
                Button(NSLocalizedString("Estimate", comment: "Estimate button")) { initsingletask() }
                    .buttonStyle(PrimaryButtonStyle())
            } else {
                // Execute estimated
                Button(NSLocalizedString("Execute", comment: "Execute button")) { singletask() }
                    .buttonStyle(PrimaryButtonStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.red, lineWidth: 5)
                    )
                    .onDisappear(perform: {
                        completed()
                    })
            }
        }
    }

    // No estimation, just execute task now
    var executenow: some View {
        Button(NSLocalizedString("Now", comment: "Now button")) { singletasknow() }
            .buttonStyle(PrimaryButtonStyle())
            .onChange(of: singletasknowstate.executetasknowstate, perform: { _ in
                if singletasknowstate.executetasknowstate == .completed { completed() }
            })
    }

    // Shortcuts
    var labelshortcutestimation: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusstartestimation = false
                // Guard statement must be after resetting properties to false
                initsingletask()
            })
    }

    var labelshortcutexecute: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusstartexecution = false
                // Guard statement must be after resetting properties to false
                singletask()
            })
    }

    var progressviewexecute: some View {
        ProgressView(NSLocalizedString("", comment: "Execute tasks") + "…",
                     value: inprogresscountrsyncoutput.getinprogress(),
                     total: Double(inprogresscountrsyncoutput.getmaxcount()))
            .onChange(of: inprogresscountrsyncoutput.getinprogress(), perform: { _ in
            })
            .progressViewStyle(GaugeProgressStyle())
            .frame(width: 50.0, height: 50.0)
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
            Text(NSLocalizedString("Pre and post task", comment: "settings"))
                .font(.title3)
                .foregroundColor(Color.blue)
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
    }

    func initsingletask() {
        setuuidforsingletask()
        singletask()
    }

    func presentoutput() {
        presentsheetview = true
    }

    func singletask() {
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
                                                   schedulesSwiftUI: rsyncUIdata.rsyncdata?.scheduleData,
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

    func singletasknow() {
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
                                                 schedulesSwiftUI: rsyncUIdata.rsyncdata?.scheduleData,
                                                 executetaskstate: singletasknowstate,
                                                 updateinprogresscount: inprogresscountrsyncoutput)
            } else {
                executetasknow =
                    ExecuteSingleTaskNow(uuids: selecteduuids,
                                         profile: rsyncUIdata.rsyncdata?.profile,
                                         configurationsSwiftUI: rsyncUIdata.rsyncdata?.configurationData,
                                         schedulesSwiftUI: rsyncUIdata.rsyncdata?.scheduleData,
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
