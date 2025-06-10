//
//  EstimateTasks.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/10/2022.
//
// swiftlint: disable line_length

import Foundation


@MainActor
final class EstimateTasks {
    var structprofile: String?
    var localconfigurations: [SynchronizeConfiguration]
    var stackoftasktobeestimated: [Int]?
    weak var localprogressdetails: ProgressDetails?
    var synchronizeIDwitherror: String = ""

    func getconfig(_ hiddenID: Int) -> SynchronizeConfiguration? {
        if let index = localconfigurations.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return localconfigurations[index]
        }
        return nil
    }

    private func startestimation() {
        if let localhiddenID = stackoftasktobeestimated?.removeFirst() {
            if let config = getconfig(localhiddenID) {
                if let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: true,
                                                                                             forDisplay: false)
                {
                    guard arguments.count > 0 else { return }
                    // Used to display details of configuration in estimation
                    localprogressdetails?.configurationtobestimated = config.id
                    let process = ProcessRsync(arguments: arguments,
                                               config: config,
                                               processtermination: processtermination)
                    process.executeProcess()
                }
            }
        }
    }

    func validatetagging(_ lines: Int, _ tagged: Bool) throws {
        if lines > SharedReference.shared.alerttagginglines, tagged == false {
            throw ErrorDatatoSynchronize.thereisdatatosynchronize(idwitherror: synchronizeIDwitherror)
        }
    }

    @discardableResult
    init(profile: String?,
         configurations: [SynchronizeConfiguration],
         selecteduuids: Set<UUID>,
         progressdetails: ProgressDetails?)
    {
        structprofile = profile
        localconfigurations = configurations
        localprogressdetails = progressdetails
        
        // Estimate selected configurations
        if selecteduuids.count > 0 {
            let configurations = localconfigurations.filter { selecteduuids.contains($0.id) && $0.task != SharedReference.shared.halted }
            stackoftasktobeestimated = configurations.map(\.hiddenID)
        } else {
            // Or estimate all tasks
            let configurations = localconfigurations.filter { $0.task != SharedReference.shared.halted }
            stackoftasktobeestimated = configurations.map(\.hiddenID)
        }
        
        localprogressdetails?.setprofileandnumberofconfigurations(structprofile, localconfigurations.count)
        startestimation()
    }
}

extension EstimateTasks {
    func processtermination(stringoutputfromrsync: [String]?, hiddenID: Int?) {
        var adjustedoutputfromrsync = false
        var suboutput: [String]?

        if (stringoutputfromrsync?.count ?? 0) > 20, let stringoutputfromrsync {
            adjustedoutputfromrsync = true
            suboutput = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)
        }

        if adjustedoutputfromrsync {
            var record = RemoteDataNumbers(stringoutputfromrsync: suboutput,
                                           config: getconfig(hiddenID ?? -1))
            adjustedoutputfromrsync = false
            Task {
                // Create data for output rsync for view
                record.outputfromrsync =
                    await CreateOutputforviewOutputRsync().createoutputforviewoutputrsync(stringoutputfromrsync)
                localprogressdetails?.appendrecordestimatedlist(record)

                if record.datatosynchronize {
                    if let config = getconfig(hiddenID ?? -1) {
                        localprogressdetails?.appenduuidwithdatatosynchronize(config.id)
                    }
                }

                // Validate that tagging is correct
                do {
                    // In case of throwing an error to identify which task
                    synchronizeIDwitherror = record.backupID
                    try validatetagging(stringoutputfromrsync?.count ?? 0, record.datatosynchronize)
                } catch let e {
                    let error = e
                    SharedReference.shared.errorobject?.alert(error: error)
                }

                // Must check inside Task AFTER async task
                if stackoftasktobeestimated?.count ?? 0 > 0 {
                    startestimation()
                } else {
                    localprogressdetails?.estimationiscomplete()
                }
            }
        } else {
            var record = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                           config: getconfig(hiddenID ?? -1))
            Task {
                // Create data for output rsync for view
                record.outputfromrsync =
                    await CreateOutputforviewOutputRsync().createoutputforviewoutputrsync(stringoutputfromrsync)
                localprogressdetails?.appendrecordestimatedlist(record)

                if record.datatosynchronize {
                    if let config = getconfig(hiddenID ?? -1) {
                        localprogressdetails?.appenduuidwithdatatosynchronize(config.id)
                    }
                }

                // Validate that tagging is correct
                do {
                    try validatetagging(stringoutputfromrsync?.count ?? 0, record.datatosynchronize)
                } catch let e {
                    let error = e
                    SharedReference.shared.errorobject?.alert(error: error)
                }

                // Must check inside Task AFTER async task
                if stackoftasktobeestimated?.count ?? 0 > 0 {
                    startestimation()
                } else {
                    localprogressdetails?.estimationiscomplete()
                }
            }
        }
    }
}

// swiftlint: enable line_length
