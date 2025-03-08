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
    weak var localestimateprogressdetails: EstimateProgressDetails?

    func getconfig(_ hiddenID: Int) -> SynchronizeConfiguration? {
        if let index = localconfigurations.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return localconfigurations[index]
        }
        return nil
    }

    func startestimation() {
        let localhiddenID = stackoftasktobeestimated?.removeFirst()
        guard localhiddenID != nil else { return }
        if let config = getconfig(localhiddenID ?? -1) {
            if let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: true,
                                                                                         forDisplay: false)
            {
                guard arguments.count > 0 else { return }
                // Used to display details of configuration in estimation
                localestimateprogressdetails?.configurationtobestimated = config.id
                let process = ProcessRsync(arguments: arguments,
                                           config: config,
                                           processtermination: processtermination)
                process.executeProcess()
            }
        }
    }

    init(profile: String?,
         configurations: [SynchronizeConfiguration],
         selecteduuids: Set<UUID>,
         estimateprogressdetails: EstimateProgressDetails?,
         filter: String)
    {
        structprofile = profile
        localconfigurations = configurations
        localestimateprogressdetails = estimateprogressdetails
        let filteredconfigurations = localconfigurations.filter { filter.isEmpty ? true : $0.backupID.contains(filter) }
        // Estimate selected configurations
        if selecteduuids.count > 0 {
            let configurations = filteredconfigurations.filter { selecteduuids.contains($0.id) && $0.task != SharedReference.shared.halted }
            stackoftasktobeestimated = configurations.map(\.hiddenID)
        } else {
            // Or estimate all tasks
            let configurations = filteredconfigurations.filter { $0.task != SharedReference.shared.halted }
            stackoftasktobeestimated = configurations.map(\.hiddenID)
        }
        localestimateprogressdetails?.setprofileandnumberofconfigurations(structprofile ?? SharedReference.shared.defaultprofile, localconfigurations.count)
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
                localestimateprogressdetails?.appendrecordestimatedlist(record)

                if record.datatosynchronize {
                    if let config = getconfig(hiddenID ?? -1) {
                        localestimateprogressdetails?.appenduuidwithdatatosynchronize(config.id)
                    }
                }

                // Must check inside Task AFTER async task
                if stackoftasktobeestimated?.count ?? 0 > 0 {
                    startestimation()
                } else {
                    localestimateprogressdetails?.estimationiscomplete()
                }
            }
        } else {
            var record = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                           config: getconfig(hiddenID ?? -1))
            Task {
                // Create data for output rsync for view
                record.outputfromrsync =
                    await CreateOutputforviewOutputRsync().createoutputforviewoutputrsync(stringoutputfromrsync)
                localestimateprogressdetails?.appendrecordestimatedlist(record)

                if record.datatosynchronize {
                    if let config = getconfig(hiddenID ?? -1) {
                        localestimateprogressdetails?.appenduuidwithdatatosynchronize(config.id)
                    }
                }

                // Must check inside Task AFTER async task
                if stackoftasktobeestimated?.count ?? 0 > 0 {
                    startestimation()
                } else {
                    localestimateprogressdetails?.estimationiscomplete()
                }
            }
        }
    }
}

// swiftlint: enable line_length
