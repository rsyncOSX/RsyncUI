//
//  Estimate.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/12/2025.
//

import Foundation
import OSLog
import ParseRsyncOutput
import RsyncProcessStreaming

@MainActor
final class Estimate {
    private var localconfigurations: [SynchronizeConfiguration]
    private var structprofile: String?
    private var itemizechanges: Bool = false

    weak var localprogressdetails: ProgressDetails?
    /// Optional completion for callers without a view, such as App Intents.
    private var onComplete: ((Bool) -> Void)?

    var stackoftasks: [Int]?
    private let requestedIDs: Set<UUID>
    private var isCancelled = false

    // Streaming strong references
    private var streamingHandlers: RsyncProcessStreaming.ProcessHandlers?
    private var activeStreamingProcess: RsyncProcessStreaming.RsyncProcess?

    func cancel() {
        SharedReference.shared.quitAfterExternalExecution = false
        isCancelled = true
        stackoftasks = nil
        if let process = activeStreamingProcess, process.isRunning {
            process.cancel()
        }
    }

    private func completeEstimation(success: Bool = false) {
        localprogressdetails?.estimationIsComplete()
        activeStreamingProcess = nil
        streamingHandlers = nil
        let records = localprogressdetails?.estimatedlist ?? []
        let complete = success && Self.hasCompletePreview(records, for: requestedIDs)
        if let onComplete {
            self.onComplete = nil
            onComplete(complete)
        }
        guard complete else {
            SharedReference.shared.quitAfterExternalExecution = false
            return
        }
        if !records.contains(where: \.datatosynchronize) {
            SharedReference.shared.finishExternalExecution(success: true)
        }
    }

    static func hasCompletePreview(_ records: [RemoteDataNumbers], for requestedIDs: Set<UUID>) -> Bool {
        !requestedIDs.isEmpty && records.count == requestedIDs.count &&
            Set(records.map(\.id)) == requestedIDs && records.allSatisfy(\.hasUsableStatistics)
    }

    private func getConfig(_ hiddenID: Int) -> SynchronizeConfiguration? {
        if let index = localconfigurations.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return localconfigurations[index]
        }
        return nil
    }

    private func startEstimation() {
        guard !isCancelled else { return }
        guard (stackoftasks?.count ?? 0) > 0 else {
            completeEstimation(success: true)
            return
        }

        streamingHandlers = CreateStreamingHandlers().createResultHandlers(
            fileHandler: { _ in },
            processTermination: { output, hiddenID, outcome in
                guard !self.isCancelled, outcome == .success else {
                    self.stackoftasks = nil
                    self.completeEstimation()
                    return
                }
                self.processTermination(stringoutputfromrsync: output, hiddenID)
            }
        )

        guard
            let localhiddenID = stackoftasks?.removeFirst(),
            let config = getConfig(localhiddenID),
            let arguments = ArgumentsSynchronize(config: config).argumentsSynchronize(dryRun: true, forDisplay: false)
        else {
            completeEstimation()
            return
        }

        itemizechanges = arguments.contains("--itemize-changes")
        // Used to display details of configuration in estimation
        localprogressdetails?.configurationtobestimated = config.id

        // Must check valid rsync exists
        guard SharedReference.shared.norsync == false, config.task != SharedReference.shared.halted, let streamingHandlers else {
            completeEstimation()
            return
        }

        if SharedReference.shared.validatearguments {
            do {
                try ValidateArguments().validate(config: config, arguments: arguments, isDryRun: true)
            } catch let err {
                let error = err
                SharedReference.shared.errorobject?.alert(error: error)
                completeEstimation()
                return
            }
        }
        let process = RsyncProcessStreaming.RsyncProcess(
            arguments: arguments,
            hiddenID: config.hiddenID,
            handlers: streamingHandlers,
            useFileHandler: false
        )

        do {
            try process.executeProcess()
            activeStreamingProcess = process
        } catch let err {
            let error = err
            SharedReference.shared.errorobject?.alert(error: error)
            completeEstimation()
        }
    }

    static func start(profile: String?,
                      configurations: [SynchronizeConfiguration],
                      selecteduuids: Set<UUID>,
                      progressdetails: ProgressDetails?,
                      onComplete: ((Bool) -> Void)? = nil) -> Estimate {
        let estimate = Estimate(profile: profile,
                                configurations: configurations,
                                selecteduuids: selecteduuids,
                                progressdetails: progressdetails)
        estimate.onComplete = onComplete
        estimate.localprogressdetails?.setProfileAndNumberOfConfigurations(
            estimate.structprofile,
            estimate.stackoftasks?.count ?? 0
        )
        Logger.process.debugMessageOnly("Estimate: START ESTIMATION")
        estimate.startEstimation()
        return estimate
    }

    private init(profile: String?,
                 configurations: [SynchronizeConfiguration],
                 selecteduuids: Set<UUID>,
                 progressdetails: ProgressDetails?) {
        structprofile = profile
        localconfigurations = configurations
        localprogressdetails = progressdetails

        let requested = configurations.filter {
            $0.task != SharedReference.shared.halted && (selecteduuids.isEmpty || selecteduuids.contains($0.id))
        }
        requestedIDs = Set(requested.map(\.id))
        stackoftasks = requested.map(\.hiddenID)
    }

    deinit {
        Logger.process.debugMessageOnly("Estimate: DEINIT")
        self.stackoftasks = nil
    }
}

extension Estimate {
    private func processTermination(stringoutputfromrsync: [String]?, _ hiddenID: Int?) {
        var adjustedoutputfromrsync = false
        var suboutput: [String]?

        if (stringoutputfromrsync?.count ?? 0) > 20, let stringoutputfromrsync {
            adjustedoutputfromrsync = true
            suboutput = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)
        }

        let outputToProcess = adjustedoutputfromrsync ? suboutput : stringoutputfromrsync
        processRecordAndContinueEstimation(
            outputToProcess: outputToProcess,
            originalOutput: stringoutputfromrsync,
            hiddenID: hiddenID
        )
    }

    private func processRecordAndContinueEstimation(
        outputToProcess: [String]?,
        originalOutput: [String]?,
        hiddenID: Int?
    ) {
        guard let hiddenID else {
            completeEstimation()
            return
        }

        var record = RemoteDataNumbers(
            stringoutputfromrsync: outputToProcess,
            config: getConfig(hiddenID)
        )
        // Mark if arguments --itemize-changes and --update are included within the arguments
        record.itemizechanges = itemizechanges

        let output = CreateOutputforView().createOutputForView(originalOutput)
        record.outputfromrsync = output
        localprogressdetails?.appendRecordEstimatedList(record)

        if record.datatosynchronize, let config = getConfig(hiddenID) {
            localprogressdetails?.appendUUIDWithDataToSynchronize(config.id)
        }

        if let count = stackoftasks?.count, count > 0 {
            // Estimate next task
            // Release references before starting next to avoid growth
            activeStreamingProcess = nil
            streamingHandlers = nil
            startEstimation()
        } else {
            Logger.process.debugMessageOnly("Estimate: ESTIMATION is completed")
            completeEstimation(success: true)
            return
        }
    }
}
