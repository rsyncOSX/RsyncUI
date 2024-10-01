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
    @Bindable var executeprogressdetails: ExecuteProgressDetails
    @Binding var selecteduuids: Set<UUID>
    @Binding var path: [Tasks]

    @State private var multipletaskstate = ExecuteState()
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
                executeprogressdetails: executeprogressdetails,
                max: maxcount
            )
            .onChange(of: executeprogressdetails.hiddenIDatwork) {
                maxcount = executeprogressdetails.getmaxcountbytask()
            }

            if multipletaskstate.executestate == .execute { ProgressView() }
            if focusaborttask { labelaborttask }
        }
        .onAppear(perform: {
            executemultipleestimatedtasks()
        })
        .onDisappear(perform: {
            executeprogressdetails.estimatedlist = nil
            if SharedReference.shared.process != nil {
                _ = InterruptProcess()
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
        executeprogressdetails.hiddenIDatwork = -1
        multipletaskstate.updateexecutestate(state: .start)
        selecteduuids.removeAll()
        _ = InterruptProcess()
        path.removeAll()
    }

    func executemultipleestimatedtasks() {
        Logger.process.info("executemultipleestimatedtasks(): \(selecteduuids, privacy: .public)")
        var uuids: Set<SynchronizeConfiguration.ID>?
        if selecteduuids.count > 0 {
            uuids = selecteduuids
        } else if executeprogressdetails.estimatedlist?.count ?? 0 > 0 {
            let uuidcount = executeprogressdetails.estimatedlist?.compactMap(\.id)
            uuids = Set<SynchronizeConfiguration.ID>()
            for i in 0 ..< (uuidcount?.count ?? 0) where
                executeprogressdetails.estimatedlist?[i].datatosynchronize == true
            {
                uuids?.insert(uuidcount?[i] ?? UUID())
            }
        }
        guard (uuids?.count ?? 0) > 0 else {
            executeprogressdetails.estimatedlist = nil
            path.removeAll()
            return
        }
        if let uuids {
            if let configurations = rsyncUIdata.configurations {
                multipletaskstate.updateexecutestate(state: .execute)
                ExecuteMultipleTasks(uuids: uuids,
                                     profile: rsyncUIdata.profile,
                                     rsyncuiconfigurations: configurations,
                                     multipletaskstateDelegate: multipletaskstate,
                                     executeprogressdetailsDelegate: executeprogressdetails,
                                     filehandler: filehandler,
                                     updateconfigurations: updateconfigurations)
            }
        }
    }

    func updateconfigurations(_ configurations: [SynchronizeConfiguration]) {
        Logger.process.info("Updateconfigurations() in memory\nReset data and return to main task view")
        rsyncUIdata.configurations = configurations
        executeprogressdetails.hiddenIDatwork = -1
        executeprogressdetails.estimatedlist = nil
        multipletaskstate.updateexecutestate(state: .start)
        selecteduuids.removeAll()
        path.append(Tasks(task: .completedview))
    }
}
