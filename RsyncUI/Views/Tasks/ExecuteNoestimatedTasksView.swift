//
//  ExecuteNoestimatedTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import OSLog
import SwiftUI

struct ExecuteNoestimatedTasksView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata

    @Binding var reload: Bool
    @Binding var selecteduuids: Set<UUID>
    @Binding var path: [Tasks]

    // Must be stateobject
    @State private var executeasynccompleted = ExecuteAsyncCompleted()
    @State private var filterstring: String = ""
    @State private var progressviewshowinfo: Bool = true
    @State private var executealltasksasync: ExecuteTasksAsync?
    @State private var confirmdelete = false
    @State private var focusaborttask: Bool = false

    var body: some View {
        ZStack {
            ListofTasksView(
                selecteduuids: $selecteduuids,
                filterstring: $filterstring
            )

            if executeasynccompleted.executeasyncnoestimationcompleted == true { labelcompleted }
            if progressviewshowinfo { AlertToast(displayMode: .alert, type: .loading) }
            if focusaborttask { labelaborttask }
        }
        .onAppear(perform: {
            Task {
                await executeallnotestimatedtasks()
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

    // When status execution is .completed, present label and execute completed.
    var labelcompleted: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                completed()
                path.removeAll()
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

extension ExecuteNoestimatedTasksView {
    func completed() {
        reload = true
        progressviewshowinfo = false
        executeasynccompleted.reset()
    }

    func abort() {
        selecteduuids.removeAll()
        _ = InterruptProcess()
        reload = true
        progressviewshowinfo = false
        executeasynccompleted.reset()
    }

    func executeallnotestimatedtasks() async {
        Logger.process.info("ExecuteallNOtestimatedtasks() : \(selecteduuids, privacy: .public)")
        executeasynccompleted.startasyncexecutealltasksnoestimation()
        executealltasksasync =
            ExecuteTasksAsync(profile: rsyncUIdata.profile,
                              configurations: rsyncUIdata,
                              executeasynccompleted: executeasynccompleted,
                              uuids: selecteduuids,
                              filter: filterstring)
        await executealltasksasync?.startexecution()
    }
}

@Observable
final class ExecuteAsyncCompleted {
    var executeasyncnoestimationcompleted: Bool = false
    var estimatedlist: [RemoteDataNumbers]?
    // set uuid if data to be transferred
    var uuids = Set<UUID>()

    func asyncexecutealltasksnoestiamtioncomplete() {
        executeasyncnoestimationcompleted = true
    }

    func startasyncexecutealltasksnoestimation() {
        executeasyncnoestimationcompleted = false
    }

    func appendrecordexecutedlist(_ record: RemoteDataNumbers) {
        if estimatedlist == nil {
            estimatedlist = [RemoteDataNumbers]()
        }
        estimatedlist?.append(record)
    }

    func appenduuid(_ id: UUID) {
        uuids.insert(id)
    }

    func reset() {
        uuids.removeAll()
        estimatedlist = nil
    }
}
