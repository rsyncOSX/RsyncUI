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

    weak var localprogressdetails: ProgressDetails?

    var stackoftasks: [Int]?
    var synchronizeIDwitherror: String = ""

    // Streaming strong references
    private var streamingHandlers: RsyncProcessStreaming.ProcessHandlers?
    private var activeStreamingProcess: RsyncProcessStreaming.RsyncProcess?

    private func getConfig(_ hiddenID: Int) -> SynchronizeConfiguration? {
        if let index = localconfigurations.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return localconfigurations[index]
        }
        return nil
    }

    private func startEstimation() {
        guard (stackoftasks?.count ?? 0) > 0 else { return }

        streamingHandlers = CreateStreamingHandlers().createHandlers(
            fileHandler: { _ in },
            processTermination: { output, hiddenID in
                self.processTermination(stringoutputfromrsync: output, hiddenID)
            }
        )

        guard
            let localhiddenID = stackoftasks?.removeFirst(),
            let config = getConfig(localhiddenID),
            let arguments = ArgumentsSynchronize(config: config).argumentsSynchronize(dryRun: true, forDisplay: false)
        else { return }

        // Used to display details of configuration in estimation
        localprogressdetails?.configurationtobestimated = config.id

        // Must check valid rsync exists
        guard SharedReference.shared.norsync == false else { return }
        guard config.task != SharedReference.shared.halted else { return }
        guard let streamingHandlers else { return }

        if SharedReference.shared.validatearguments {
            do {
                try ValidateArguments().validate(config: config, arguments: arguments, isDryRun: true)
            } catch let err {
                let error = err
                SharedReference.shared.errorobject?.alert(error: error)
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
        }
    }

    // Used in Estimate
    private func validateTagging(_ lines: Int, _ tagged: Bool) throws {
        if lines > SharedReference.shared.alerttagginglines, tagged == false {
            throw ErrorDatatoSynchronize.thereisdatatosynchronize(idwitherror: synchronizeIDwitherror)
        }
    }

    private func computestackoftasks(_ selecteduuids: Set<UUID>) -> [Int] {
        if selecteduuids.count > 0 {
            let configurations = localconfigurations.filter { selecteduuids.contains($0.id) &&
                $0.task != SharedReference.shared.halted
            }
            return configurations.map(\.hiddenID)
        } else {
            // Or go for all
            let configurations = localconfigurations.filter { $0.task != SharedReference.shared.halted }
            return configurations.map(\.hiddenID)
        }
    }

    @discardableResult
    init(profile: String?,
         configurations: [SynchronizeConfiguration],
         selecteduuids: Set<UUID>,
         progressdetails: ProgressDetails?) {
        structprofile = profile
        localconfigurations = configurations
        localprogressdetails = progressdetails

        stackoftasks = computestackoftasks(selecteduuids)
        localprogressdetails?.setProfileAndNumberOfConfigurations(structprofile, stackoftasks?.count ?? 0)
        Logger.process.debugMessageOnly("Estimate: START ESTIMATION")
        startEstimation()
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
        let resolvedHiddenID = hiddenID ?? -1

        var record = RemoteDataNumbers(
            stringoutputfromrsync: outputToProcess,
            config: getConfig(resolvedHiddenID)
        )

        Task.detached { [self, originalOutput, outputToProcess] in
            // Create data for output rsync for view off-main
            let output = await ActorCreateOutputforView().createOutputForView(originalOutput)
            await MainActor.run {
                record.outputfromrsync = output
                self.localprogressdetails?.appendRecordEstimatedList(record)

                if record.datatosynchronize {
                    if let config = self.getConfig(resolvedHiddenID) {
                        self.localprogressdetails?.appendUUIDWithDataToSynchronize(config.id)
                    }
                }

                // Validate that tagging is correct
                do {
                    // In case of throwing an error to identify which task
                    if outputToProcess != originalOutput {
                        self.synchronizeIDwitherror = record.backupID
                    }
                    try self.validateTagging(originalOutput?.count ?? 0, record.datatosynchronize)
                } catch let err {
                    let error = err
                    SharedReference.shared.errorobject?.alert(error: error)
                }

                guard self.stackoftasks?.count ?? 0 > 0 else {
                    self.localprogressdetails?.estimationIsComplete()
                    Logger.process.debugMessageOnly("Estimate: ESTIMATION is completed")
                    // Release streaming references when completed
                    self.activeStreamingProcess = nil
                    self.streamingHandlers = nil
                    return
                }
                // Estimate next task
                // Release references before starting next to avoid growth
                self.activeStreamingProcess = nil
                self.streamingHandlers = nil
                self.startEstimation()
            }
        }
    }
}
