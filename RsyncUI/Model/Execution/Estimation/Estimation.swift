//
//  Estimation.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/01/2021.
//
//
// swiftlint:disable line_length

import Foundation

enum EstimatetaskWork: String, CaseIterable, Identifiable, CustomStringConvertible {
    case start
    case estimate
    case completed
    case error

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized }
}

final class Estimation {
    private var localconfigurationsSwiftUI: ConfigurationsSwiftUI?
    private var privatehiddenID: Int?
    private var stackoftasktobeestimated: [Int]?
    private var outputprocess: OutputfromProcess?
    private var records: [RemoteinfonumbersOnetask]?
    private var max: Int?
    private var hiddenIDs: [Int]?
    private var estimationonetask: EstimationOnetask?
    // Set if abort is executed
    private var setabort = false

    weak var stateDelegate: EstimationState?
    weak var updateestimationcountDelegate: UpdateEstimationCount?

    private func prepareandstartexecutetasks(_ configurations: [Configuration]?) {
        stackoftasktobeestimated = [Int]()
        // Multiple selected indexes
        if let hiddenIDs = self.hiddenIDs {
            for i in 0 ..< hiddenIDs.count {
                stackoftasktobeestimated?.append(hiddenIDs[i])
            }
            // Estimate all or filtered tasks
        } else {
            for i in 0 ..< (configurations?.count ?? 0) {
                let task = configurations?[i].task
                if SharedReference.shared.synctasks.contains(task ?? "") {
                    if let hiddenID = configurations?[i].hiddenID {
                        stackoftasktobeestimated?.append(hiddenID)
                    }
                }
            }
        }
        max = stackoftasktobeestimated?.count
        updateestimationcountDelegate?.setmaxcount(num: stackoftasktobeestimated?.count ?? 0)
    }

    func selectalltaskswithnumbers() {
        guard records != nil else { return }
        for i in 0 ..< (records?.count ?? 0) {
            let number = records?[i].transferredNumber ?? "0"
            let delete = records?[i].deletefiles ?? "0"
            if Int(number) ?? 0 > 0 || Int(delete) ?? 0 > 0 {
                records?[i].selected = 1
            }
        }
    }

    private func finalizeandpreparesynchronizelist() {
        guard self.records != nil else { return }
        var records = [RemoteinfonumbersOnetask]()
        for i in 0 ..< (self.records?.count ?? 0) where self.records?[i].selected == 1 {
            if let record = self.records?[i] {
                records.append(record)
            }
        }
    }

    func startestimation() {
        guard (stackoftasktobeestimated?.count ?? 0) > 0 else { return }
        if let hiddenID = stackoftasktobeestimated?.remove(at: 0) {
            privatehiddenID = hiddenID
            updateestimationcountDelegate?.sethiddenID(hiddenID)
            outputprocess = OutputfromProcess()
            estimationonetask = EstimationOnetask(hiddenID: hiddenID,
                                                  configurationsSwiftUI: localconfigurationsSwiftUI,
                                                  outputprocess: outputprocess,
                                                  local: false,
                                                  processtermination: processtermination,
                                                  filehandler: filehandler)
            estimationonetask?.startestimation()
        }
    }

    private func getconfig(hiddenID: Int?) -> Configuration? {
        if let hiddenID = hiddenID {
            if let configurations = localconfigurationsSwiftUI?.getallconfigurations()?.filter({ $0.hiddenID == hiddenID }) {
                guard configurations.count == 1 else { return nil }
                return configurations[0]
            }
        }
        return nil
    }

    init(configurationsSwiftUI: ConfigurationsSwiftUI?,
         estimationstateDelegate: EstimationState?,
         updateinprogresscount: UpdateEstimationCount?,
         uuids: Set<UUID>,
         filter: String)
    {
        localconfigurationsSwiftUI = configurationsSwiftUI
        stateDelegate = estimationstateDelegate
        updateestimationcountDelegate = updateinprogresscount
        let filteredconfigurations = configurationsSwiftUI?.getallconfigurations()?.filter { filter.isEmpty ? true : $0.backupID.contains(filter) }
        // Debug print
        // printdebugdata(uuids)
        // Debug print
        if uuids.count > 0 {
            // Estimate selected configurations
            hiddenIDs = [Int]()
            let configurations = filteredconfigurations?.filter { uuids.contains($0.id) }
            for i in 0 ..< (configurations?.count ?? 0) {
                if let hiddenID = configurations?[i].hiddenID {
                    hiddenIDs?.append(hiddenID)
                }
            }
            // Clearing old selected uuids not done, must fix
            if (configurations?.count ?? 0) == 0 {
                hiddenIDs = nil
            }
        } else {
            // Estimate all configurations
            hiddenIDs = nil
        }
        records = [RemoteinfonumbersOnetask]()
        prepareandstartexecutetasks(filteredconfigurations)
    }

    deinit {
        self.stackoftasktobeestimated = nil
        // print("deinit Estimation")
    }

    func abort() {
        stackoftasktobeestimated = nil
        estimationonetask = nil
        updateestimationcountDelegate?.resetcounts()
        setabort = true
    }

    // debug
    func printdebugdata(_ uuids: Set<UUID>) {
        print("ESTIMATION start: \(localconfigurationsSwiftUI?.getallconfigurations()?.count ?? 0) number of configurations")
        if uuids.count > 0 {
            let test = localconfigurationsSwiftUI?.getallconfigurations()?.filter { uuids.contains($0.id) }
            print("Number of configurations to estimate: \(test?.count ?? 0)")
            if (test?.count ?? 0) == 0 {
                print("PROBLEM: clearing old uuids not done properly")
                print("CLEARING old uuids and estimating all configurations: \(localconfigurationsSwiftUI?.getallconfigurations()?.count ?? 0)")
            }
        }
    }
}

extension Estimation {
    func processtermination() {
        guard setabort == false else { return }
        // print("processtermination()")
        // print("Total number of configurations to process in processtermination(): \(stackoftasktobeestimated?.count ?? 0) of \(max ?? 0)")
        updateestimationcountDelegate?.updateinprogresscount(num: Double((max ?? 0) - (stackoftasktobeestimated?.count ?? 0)))
        let record = RemoteinfonumbersOnetask(hiddenID: privatehiddenID,
                                              outputprocess: outputprocess,
                                              config: getconfig(hiddenID: privatehiddenID))
        records?.append(record)
        if Int(record.transferredNumber ?? "0") ?? 0 > 0 || Int(record.deletefiles ?? "0") ?? 0 > 0 {
            if let config = getconfig(hiddenID: privatehiddenID) {
                updateestimationcountDelegate?.appenduuid(id: config.id)
            }
        }
        // Release the estimation object
        estimationonetask = nil
        guard stackoftasktobeestimated?.count ?? 0 > 0 else {
            selectalltaskswithnumbers()
            // Prepare tasks with changes for synchronization
            finalizeandpreparesynchronizelist()
            stateDelegate?.updatestate(state: .completed)
            updateestimationcountDelegate?.setestimatedlist(records)
            return
        }
        outputprocess = OutputfromProcessRsync()
        if let hiddenID = stackoftasktobeestimated?.remove(at: 0) {
            privatehiddenID = hiddenID
            updateestimationcountDelegate?.sethiddenID(hiddenID)
            estimationonetask = EstimationOnetask(hiddenID: hiddenID,
                                                  configurationsSwiftUI: localconfigurationsSwiftUI,
                                                  outputprocess: outputprocess,
                                                  local: false,
                                                  processtermination: processtermination,
                                                  filehandler: filehandler)
            estimationonetask?.startestimation()
        }
    }

    func filehandler() {}
}
