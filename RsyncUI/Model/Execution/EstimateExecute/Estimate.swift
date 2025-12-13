//
//  Estimate.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/12/2025.
//

import Foundation
import OSLog
import ParseRsyncOutput
import RsyncProcess

@MainActor
final class Estimate {
    private var localconfigurations: [SynchronizeConfiguration]
    private var structprofile: String?

    weak var localprogressdetails: ProgressDetails?

    var stackoftasks: [Int]?
    var synchronizeIDwitherror: String = ""

    private func getConfig(_ hiddenID: Int) -> SynchronizeConfiguration? {
        if let index = localconfigurations.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return localconfigurations[index]
        }
        return nil
    }

    private func startEstimation() {
        guard (stackoftasks?.count ?? 0) > 0 else { return }

        let handlers = CreateHandlers().createHandlers(
            fileHandler: { _ in },
            processTermination: processTermination
        )

        if let localhiddenID = stackoftasks?.removeFirst() {
            if let config = getConfig(localhiddenID) {
                if let arguments = ArgumentsSynchronize(config: config).argumentsSynchronize(dryRun: true,
                                                                                             forDisplay: false) {
                    // Used to display details of configuration in estimation
                    localprogressdetails?.configurationtobestimated = config.id

                    // Must check valid rsync exists
                    guard SharedReference.shared.norsync == false else { return }
                    guard config.task != SharedReference.shared.halted else { return }

                    let process = RsyncProcess(arguments: arguments,
                                               hiddenID: config.hiddenID,
                                               handlers: handlers,
                                               useFileHandler: false)

                    do {
                        try process.executeProcess()
                    } catch let err {
                        let error = err
                        SharedReference.shared.errorobject?.alert(error: error)
                    }
                }
            }
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

        if adjustedoutputfromrsync {
            var record = RemoteDataNumbers(stringoutputfromrsync: suboutput,
                                           config: getConfig(hiddenID ?? -1))
            adjustedoutputfromrsync = false
            Task {
                // Create data for output rsync for view
                record.outputfromrsync =
                    await ActorCreateOutputforView().createOutputForView(stringoutputfromrsync)
                localprogressdetails?.appendRecordEstimatedList(record)

                if record.datatosynchronize {
                    if let config = getConfig(hiddenID ?? -1) {
                        localprogressdetails?.appendUUIDWithDataToSynchronize(config.id)
                    }
                }

                // Validate that tagging is correct
                do {
                    // In case of throwing an error to identify which task
                    synchronizeIDwitherror = record.backupID
                    try validateTagging(stringoutputfromrsync?.count ?? 0, record.datatosynchronize)
                } catch let err {
                    let error = err
                    SharedReference.shared.errorobject?.alert(error: error)
                }

                guard stackoftasks?.count ?? 0 > 0 else {
                    localprogressdetails?.estimationIsComplete()
                    Logger.process.debugMessageOnly("Estimate: ESTIMATION is completed")
                    return
                }
                // Estimate next task
                startEstimation()
            }
        } else {
            var record = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                           config: getConfig(hiddenID ?? -1))
            Task {
                // Create data for output rsync for view
                record.outputfromrsync =
                    await ActorCreateOutputforView().createOutputForView(stringoutputfromrsync)
                localprogressdetails?.appendRecordEstimatedList(record)

                if record.datatosynchronize {
                    if let config = getConfig(hiddenID ?? -1) {
                        localprogressdetails?.appendUUIDWithDataToSynchronize(config.id)
                    }
                }

                // Validate that tagging is correct
                do {
                    try validateTagging(stringoutputfromrsync?.count ?? 0, record.datatosynchronize)
                } catch let err {
                    let error = err
                    SharedReference.shared.errorobject?.alert(error: error)
                }

                guard stackoftasks?.count ?? 0 > 0 else {
                    localprogressdetails?.estimationIsComplete()
                    Logger.process.debugMessageOnly("Estimate: ESTIMATION is completed")
                    return
                }
                // Estimate next task
                startEstimation()
            }
        }
    }
}
