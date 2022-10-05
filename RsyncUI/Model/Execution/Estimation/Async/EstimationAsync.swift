//
//  EstimationAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/10/2022.
//

import Foundation

@MainActor
final class EstimationAsync {
    private var localconfigurationsSwiftUI: ConfigurationsSwiftUI?
    // private var privatehiddenID: Int?
    private var stackoftasktobeestimated: [Int]?
    private var records: [RemoteinfonumbersOnetask]?
    private var max: Int?
    private var hiddenIDs: [Int]?
    private var estimationonetask: EstimationOnetaskAsync?
    // Set if abort is executed
    private var setabort = false

    weak var stateDelegate: EstimationState?
    weak var updateestimationcountDelegate: UpdateEstimationCount?

    private func prepareandstartexecutetasks(_ configurations: [Configuration]?) {
        stackoftasktobeestimated = [Int]()
        // Multiple selected indexes
        if let hiddenIDs = hiddenIDs {
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

    @MainActor
    func startestimation() async {
        guard (stackoftasktobeestimated?.count ?? 0) > 0 else { return }
        stateDelegate?.updatestate(state: .start)
        for i in 0 ..< (stackoftasktobeestimated?.count ?? 0) {
            if let hiddenID = stackoftasktobeestimated?[i] {
                print(hiddenID)
                updateestimationcountDelegate?.sethiddenID(hiddenID)
                estimationonetask = EstimationOnetaskAsync(hiddenID: hiddenID,
                                                           configurationsSwiftUI: localconfigurationsSwiftUI,
                                                           local: false,
                                                           processtermination: processtermination)
                await estimationonetask?.startestimation()
            }
        }
        selectalltaskswithnumbers()
        // Prepare tasks with changes for synchronization
        finalizeandpreparesynchronizelist()
        stateDelegate?.updatestate(state: .completed)
        updateestimationcountDelegate?.setestimatedlist(records)
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
}

extension EstimationAsync {
    func processtermination(outputfromrsync: [String]?, hiddenID: Int?) {
        guard setabort == false else { return }
        updateestimationcountDelegate?.updateinprogresscount(num: Double((max ?? 0) - (stackoftasktobeestimated?.count ?? 0)))
        let record = RemoteinfonumbersOnetask(hiddenID: hiddenID,
                                              outputfromrsync: outputfromrsync,
                                              config: getconfig(hiddenID: estimationonetask?.hiddenID))
        records?.append(record)
        print(record)
        if Int(record.transferredNumber) ?? 0 > 0 || Int(record.deletefiles) ?? 0 > 0 {
            if let config = getconfig(hiddenID: hiddenID) {
                updateestimationcountDelegate?.appenduuid(id: config.id)
            }
        }
        // Release the estimation object
        estimationonetask = nil
    }
}
