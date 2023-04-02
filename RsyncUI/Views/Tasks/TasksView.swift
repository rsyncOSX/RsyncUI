//
//  TasksSheetstateView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/03/2023.
//
// swiftlint:disable line_length file_length

import Network
import SwiftUI

struct TasksView: View {
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

    @Binding var showeexecutestimatedview: Bool
    @Binding var showexecutenoestimateview: Bool
    @Binding var showexecutenoestiamteonetask: Bool

    @State private var inwork: Int = -1

    // Focus buttons from the menu
    @State private var focusstartestimation: Bool = false
    @State private var focusstartexecution: Bool = false
    @State private var focusselecttask: Bool = false
    @State private var focusfirsttaskinfo: Bool = false
    @State private var focusdeletetask: Bool = false
    @State private var focusshowinfotask: Bool = false
    @State private var focusaborttask: Bool = false

    @State private var filterstring: String = ""
    // Which sidebar function
    @Binding var selection: NavigationItem?
    // Delete
    @State private var confirmdeletemenu: Bool = false
    // Local data for present local and remote info about task
    @State private var localdata: [String] = []
    // Modale view
    @State private var modaleview = false
    @StateObject var sheetchooser = SheetChooser()
    // Repeat
    @State private var repeatisneabled: Bool = false
    @State private var timer: Double = 600

    var body: some View {
        ZStack {
            ListofTasksProgress(selectedconfig: $selectedconfig.onChange {
                guard selectedconfig != nil else { return }
                if alltasksestimated {
                    sheetchooser.sheet = .dryrun
                    modaleview = true
                }
            },
            selecteduuids: $selecteduuids,
            inwork: $inwork,
            filterstring: $filterstring,
            reload: $reload,
            confirmdelete: $confirmdeletemenu)

            // Remember max 10 in one Group
            Group {
                if focusstartestimation { labelstartestimation }
                if focusstartexecution { labelstartexecution }
                if focusselecttask { labelselecttask }
                if focusfirsttaskinfo { labelfirsttime }
                if focusdeletetask { labeldeletetask }
                if focusshowinfotask { showinfotask }
                if focusaborttask { labelaborttask }
                if inprogresscountmultipletask.estimateasync { progressviewestimateasync }
                if repeatisneabled { repeattitle }
            }
        }

        HStack {
            VStack(alignment: .center) {
                HStack {
                    Button("Estimate") { estimate() }
                        .buttonStyle(PrimaryButtonStyle())
                        .tooltip("Shortcut ⌘E")

                    Button("Execute") { execute() }
                        .buttonStyle(PrimaryButtonStyle())
                        .tooltip("Shortcut ⌘R")

                    Button("DryRun") {
                        if selectedconfig != nil {
                            sheetchooser.sheet = .estimateddetailsview
                        } else {
                            sheetchooser.sheet = .dryrun
                        }
                        modaleview = true
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Reset") {
                        selecteduuids.removeAll()
                        reset()
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("List") {
                        sheetchooser.sheet = .alltasksview
                        modaleview = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }

            Spacer()

            ZStack {
                VStack {
                    if alltasksestimated { alltasksestimatedtext }
                    if estimationstate.estimationstate != .estimate { footer }
                }
            }

            Spacer()

            HStack {
                ToggleViewDefault(NSLocalizedString("Repeat", comment: ""), $repeatisneabled.onChange {
                    if repeatisneabled == false {
                        SharedReference.shared.workitem?.cancel()
                        SharedReference.shared.workitem = nil
                    } else {
                        repeattasks()
                    }
                })

                timerpicker
            }

            Button("Abort") { abort() }
                .buttonStyle(AbortButtonStyle())
                .tooltip("Shortcut ⌘A")
        }
        .focusedSceneValue(\.startestimation, $focusstartestimation)
        .focusedSceneValue(\.startexecution, $focusstartexecution)
        .focusedSceneValue(\.selecttask, $focusselecttask)
        .focusedSceneValue(\.firsttaskinfo, $focusfirsttaskinfo)
        .focusedSceneValue(\.deletetask, $focusdeletetask)
        .focusedSceneValue(\.showinfotask, $focusshowinfotask)
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .task {
            // Discover if firsttime use, if true present view for firsttime
            if SharedReference.shared.firsttime {
                sheetchooser.sheet = .firsttime
                modaleview = true
            }
        }
        .sheet(isPresented: $modaleview) { makeSheet() }
    }

    @ViewBuilder
    func makeSheet() -> some View {
        switch sheetchooser.sheet {
        case .dryrun:
            if inprogresscountmultipletask.getestimatedlist()?.count ?? 0 > 0 && selectedconfig != nil {
                DetailsViewAlreadyEstimated(selectedconfig: $selectedconfig,
                                            reload: $reload,
                                            isPresented: $modaleview,
                                            estimatedlist: inprogresscountmultipletask.getestimatedlist() ?? [])
            } else {
                OutputEstimatedView(isPresented: $modaleview,
                                    selecteduuids: $selecteduuids,
                                    execute: $focusstartexecution,
                                    estimatedlist: inprogresscountmultipletask.getestimatedlist() ?? [])
            }
        case .estimateddetailsview:
            DetailsView(selectedconfig: $selectedconfig,
                        reload: $reload,
                        isPresented: $modaleview)
        case .alltasksview:
            AlltasksView(isPresented: $modaleview)
        case .firsttime:
            FirsttimeView(dismiss: $modaleview,
                          selection: $selection)
        case .localremoteinfo:
            LocalRemoteInfoView(dismiss: $modaleview,
                                localdata: $localdata,
                                selectedconfig: $selectedconfig)
        }
    }

    var progressviewestimateasync: some View {
        ProgressView()
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
                            EstimateAlltasksAsync(profile: rsyncUIdata.configurationsfromstore?.profile,
                                                  configurationsSwiftUI: rsyncUIdata.configurationsfromstore?.configurationData,
                                                  updateinprogresscount: inprogresscountmultipletask,
                                                  uuids: selecteduuids,
                                                  filter: filterstring)
                        await estimatealltasksasync.startexecution()
                    }
                }
            }
            .onDisappear {
                sheetchooser.sheet = .dryrun
                modaleview = true
                focusstartestimation = false
            }
    }

    var showinfotask: some View {
        ProgressView()
            .onAppear(perform: {
                let argumentslocalinfo = ArgumentsLocalcatalogInfo(config: selectedconfig)
                    .argumentslocalcataloginfo(dryRun: true, forDisplay: false)
                guard argumentslocalinfo != nil else {
                    focusshowinfotask = false
                    return
                }
                let tasklocalinfo = RsyncAsync(arguments: argumentslocalinfo,
                                               processtermination: processtermination)
                Task {
                    await tasklocalinfo.executeProcess()
                }
            })
    }

    var alltasksestimated: Bool {
        return inprogresscountmultipletask.getestimatedlist()?.count == rsyncUIdata.configurations?.count
    }

    var alltasksestimatedtext: some View {
        Text("All tasks are estimated - select task to view details or Reset for reset")
    }

    var labelstartestimation: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                estimate()
            })
    }

    var labelstartexecution: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                execute()
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
                sheetchooser.sheet = .firsttime
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

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }

    var footer: some View {
        Text("Most recent updated tasks on top of list")
            .foregroundColor(Color.blue)
    }

    var repeattitle: some View {
        HStack {
            Text("Repeat is ON: ")
                .modifier(Tagheading(.title, .leading))
                .foregroundColor(Color.blue)

            Counter(count: $timer)
                .foregroundColor(Color.blue)
        }
    }

    var timerpicker: some View {
        HStack {
            Picker("", selection: $timer.onChange {
                SharedReference.shared.workitem?.cancel()
                SharedReference.shared.workitem = nil
                if repeatisneabled == true {
                    repeattasks()
                }
            }) {
                ForEach(Timervalues().values.sorted(by: <), id: \.self) { value in
                    switch value {
                    case 300.0:
                        Text("5 min")
                            .tag(value)
                    case 600.0:
                        Text("10 min")
                            .tag(value)
                    case 1800.0:
                        Text("30 min")
                            .tag(value)
                    case 2700.0:
                        Text("45 min")
                            .tag(value)
                    case 3600.0:
                        Text("1 hour")
                            .tag(value)
                    case 7200.0:
                        Text("2 hours")
                            .tag(value)
                    default:
                        Text(String(value))
                            .tag(value)
                    }
                }
            }
            .frame(width: 80)
            .accentColor(.blue)
        }
    }
}

extension TasksView {
    func estimate() {
        inprogresscountmultipletask.resetcounts()
        executedetails.resetcounter()
        inprogresscountmultipletask.startestimateasync()
    }

    func execute() {
        selecteduuids = inprogresscountmultipletask.getuuids()
        guard selecteduuids.count > 0 else {
            if selectedconfig == nil {
                // Execute all tasks, no estimate
                showexecutenoestimateview = true
                showexecutenoestiamteonetask = false
            } else {
                // Execute one task, no estimte
                showexecutenoestiamteonetask = true
                showexecutenoestimateview = false
            }
            return
        }
        // Execute all estimated tasks.
        estimationstate.updatestate(state: .start)
        executedetails.resetcounter()
        executedetails.setestimatedlist(inprogresscountmultipletask.getestimatedlist())
        showeexecutestimatedview = true
    }

    func reset() {
        inwork = -1
        inprogresscountmultipletask.resetcounts()
        estimationstate.updatestate(state: .start)
        selectedconfig = nil
        inprogresscountmultipletask.estimateasync = false
        sheetchooser.sheet = .dryrun
    }

    func abort() {
        selecteduuids.removeAll()
        estimationstate.updatestate(state: .start)
        inprogresscountmultipletask.resetcounts()
        _ = InterruptProcess()
        inwork = -1
        reload = true
        focusstartestimation = false
        focusstartexecution = false
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

    // For showinfo about one task
    func processtermination(data: [String]?) {
        localdata = data ?? []
        focusshowinfotask = false
        sheetchooser.sheet = .localremoteinfo
        modaleview = true
    }

    func repeattasks() {
        SharedReference.shared.workitem = DispatchWorkItem {
            focusstartexecution = true
        }
        let time = DispatchTime.now() + timer
        if let workitem = SharedReference.shared.workitem {
            DispatchQueue.main.asyncAfter(deadline: time, execute: workitem)
        }
    }
}

enum Sheet: String, Identifiable {
    case dryrun, estimateddetailsview, alltasksview, firsttime, localremoteinfo
    var id: String { rawValue }
}

final class SheetChooser: ObservableObject {
    // Which sheet to present
    // Do not redraw view when changing
    // no @Publised
    var sheet: Sheet = .dryrun
}

struct Counter: View {
    @Binding var count: Double
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        Text("\(Int(count / 60)) " + "minutes")
            .font(.largeTitle)
            .onReceive(timer) { _ in
                count -= 60
                if count <= 0 {
                    timer.upstream.connect().cancel()
                }
            }
    }

    var timervalue: Double {
        switch count {
        case 300:
            return 30
        case 600:
            return 60
        case 1800:
            return 180
        case 2700:
            return 270
        case 3600:
            return 360
        case 7200:
            return 720
        default:
            return 60
        }
    }
}

struct Timervalues {
    let values: Set = [300.0, 600.0, 1800.0, 2700.0, 3600.0, 7200.0]
}

// swiftlint:enable line_length file_length
