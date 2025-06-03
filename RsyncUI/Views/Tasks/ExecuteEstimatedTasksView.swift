//
//  ExecuteEstimatedTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import OSLog
import SwiftUI

struct ExecuteEstimatedTasksView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Bindable var estimateprogressdetails: ProgressDetails
    @Binding var selecteduuids: Set<UUID>
    @Binding var path: [Tasks]

    @State private var executestate = ExecuteState()
    @State private var filterstring: String = ""
    @State private var focusaborttask: Bool = false
    @State private var doubleclick: Bool = false
    // Progress of synchronization
    @State private var progress: Double = 0
    @State private var maxcount: Double = 0

    var body: some View {
        ZStack {
            ListofTasksMainView(
                rsyncUIdata: rsyncUIdata,
                selecteduuids: $selecteduuids,
                filterstring: $filterstring,
                doubleclick: $doubleclick,
                progress: $progress,
                estimateprogressdetails: estimateprogressdetails,
                max: maxcount
            )
            .onChange(of: estimateprogressdetails.hiddenIDatwork) {
                maxcount = estimateprogressdetails.getmaxcountbytask()
            }

            if executestate.executestate == .execute { ProgressView() }
            if focusaborttask { labelaborttask }
        }
        .onAppear(perform: {
            executemultipleestimatedtasks()
        })
        .onDisappear(perform: {
            estimateprogressdetails.estimatedlist = nil
            rsyncUIdata.executetasksinprogress = false
            if SharedReference.shared.process != nil {
                InterruptProcess()
            }
        })
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .toolbar(content: {
            ToolbarItem {
                Button {
                    abort()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .help("Abort (⌘K)")
            }
        })
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }
}

extension ExecuteEstimatedTasksView {
    func filehandler(count: Int) {
        progress = Double(count)
    }

    func abort() {
        estimateprogressdetails.hiddenIDatwork = -1
        executestate.updateexecutestate(state: .start)
        selecteduuids.removeAll()
        InterruptProcess()
        path.removeAll()
    }

    func executemultipleestimatedtasks() {
        var adjustedselecteduuids: Set<SynchronizeConfiguration.ID>?
        if selecteduuids.count > 0 {
            adjustedselecteduuids = selecteduuids
        } else {
            if let estimatedlist = estimateprogressdetails.estimatedlist {
                adjustedselecteduuids = Set<SynchronizeConfiguration.ID>()
                _ = estimatedlist.map { estimate in
                    if estimate.datatosynchronize == true {
                        adjustedselecteduuids?.insert(estimate.id)
                    }
                }
            }
        }
        guard (adjustedselecteduuids?.count ?? 0) > 0 else {
            estimateprogressdetails.estimatedlist = nil
            rsyncUIdata.executetasksinprogress = false
            path.removeAll()
            return
        }
        if let adjustedselecteduuids {
            Logger.process.info("ExecuteEstimatedTasksView: executemultipleestimatedtasks(): \(adjustedselecteduuids, privacy: .public)")
            if let configurations = rsyncUIdata.configurations {
                executestate.updateexecutestate(state: .execute)
                ExecuteMultipleTasks(profile: rsyncUIdata.profile,
                                     rsyncuiconfigurations: configurations,
                                     selecteduuids: adjustedselecteduuids,
                                     executestateDelegate: executestate,
                                     estimateprogressdetailsDelegate: estimateprogressdetails,
                                     filehandler: filehandler,
                                     updateconfigurations: updateconfigurations)
            }
        }
    }

    func updateconfigurations(_ configurations: [SynchronizeConfiguration]) {
        Logger.process.info("ExecuteEstimatedTasksView: updateconfigurations() in memory\nReset data and return to MAIN THREAD task view")
        rsyncUIdata.configurations = configurations
        estimateprogressdetails.hiddenIDatwork = -1
        estimateprogressdetails.estimatedlist = nil
        rsyncUIdata.executetasksinprogress = false
        executestate.updateexecutestate(state: .start)
        selecteduuids.removeAll()
        path.append(Tasks(task: .completedview))
    }
}
