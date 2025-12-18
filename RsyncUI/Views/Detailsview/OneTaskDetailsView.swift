//
//  OneTaskDetailsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import Foundation
import Observation
import OSLog
import RsyncProcessStreaming
import SwiftUI

struct OneTaskDetailsView: View {
    @Bindable var progressdetails: ProgressDetails
    @State private var estimateiscompleted = false
    @State private var remotedatanumbers: RemoteDataNumbers?
    // Streaming strong references
    @State private var streamingHandlers: RsyncProcessStreaming.ProcessHandlers?
    @State private var activeStreamingProcess: RsyncProcessStreaming.RsyncProcess?

    let selecteduuids: Set<SynchronizeConfiguration.ID>
    let configurations: [SynchronizeConfiguration]

    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                if estimateiscompleted == true {
                    if let remotedatanumbers {
                        DetailsView(remotedatanumbers: remotedatanumbers)
                    }
                } else {
                    VStack {
                        // Only one task is estimated if selected, if more than one
                        // task is selected multiple estimation is selected. That is why
                        // that is why (uuid: selecteduuids.first)
                        if let config = getConfig(uuid: selecteduuids.first) {
                            Text("Estimating now: " + "\(config.backupID)")
                                .foregroundColor(.green)
                                .font(.title)
                        }

                        ProgressView()
                    }
                }
            }
        }
        .onAppear {
            var selectedconfig: SynchronizeConfiguration?
            let selected = configurations.filter { config in
                selecteduuids.contains(config.id)
            }
            if selected.count == 1 {
                selectedconfig = selected[0]
            }
            let arguments = ArgumentsSynchronize(config: selectedconfig)
                .argumentsSynchronize(dryRun: true, forDisplay: false)
            guard arguments != nil else { return }

            streamingHandlers = CreateStreamingHandlers().createHandlersWithCleanup(
                fileHandler: { _ in },
                processTermination: { output, hiddenID in
                    processTermination(stringoutputfromrsync: output, hiddenID: hiddenID)
                },
                cleanup: { activeStreamingProcess = nil; streamingHandlers = nil }
            )

            // Must check valid rsync exists
            guard SharedReference.shared.norsync == false else { return }
            guard selectedconfig?.task != SharedReference.shared.halted else { return }
            guard let streamingHandlers else { return }
            guard let arguments else { return }

            let process = RsyncProcessStreaming.RsyncProcess(
                arguments: arguments,
                hiddenID: selectedconfig?.hiddenID ?? -1,
                handlers: streamingHandlers,
                useFileHandler: false
            )

            do {
                try process.executeProcess()
                activeStreamingProcess = process
            } catch let err {
                let error = err
                SharedReference.shared.errorobject?.alert(error: error)
            }
        }
    }

    private func getConfig(uuid: UUID?) -> SynchronizeConfiguration? {
        if let index = configurations.firstIndex(where: { $0.id == uuid }) {
            return configurations[index]
        }
        return nil
    }

    func validateTagging(_ lines: Int, _ tagged: Bool) throws {
        if lines > SharedReference.shared.alerttagginglines, tagged == false {
            throw ErrorDatatoSynchronize.thereisdatatosynchronize(idwitherror: "Current Synchronization ID")
        }
    }

    @MainActor
    func processTermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        var selectedconfig: SynchronizeConfiguration?
        let selected = configurations.filter { config in
            selecteduuids.contains(config.id)
        }
        if selected.count == 1 {
            selectedconfig = selected[0]
        }

        let lines = stringoutputfromrsync?.count ?? 0
        let threshold = SharedReference.shared.alerttagginglines
        let prepared: [String]? = if lines > threshold, let data = stringoutputfromrsync {
            PrepareOutputFromRsync().prepareOutputFromRsync(data)
        } else {
            stringoutputfromrsync
        }

        remotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: prepared,
                                              config: selectedconfig)

        // Validate that tagging is correct
        do {
            try validateTagging(stringoutputfromrsync?.count ?? 0, remotedatanumbers?.datatosynchronize ?? true)
        } catch let err {
            let error = err
            SharedReference.shared.errorobject?.alert(error: error)
        }

        Task { @MainActor in
            remotedatanumbers?.outputfromrsync = await ActorCreateOutputforView().createOutputForView(stringoutputfromrsync)

            if let remotedatanumbers {
                progressdetails.appendRecordEstimatedList(remotedatanumbers)
            }

            estimateiscompleted = true
            // Release streaming references to avoid retain cycles
            activeStreamingProcess = nil
            streamingHandlers = nil
        }
    }
}
