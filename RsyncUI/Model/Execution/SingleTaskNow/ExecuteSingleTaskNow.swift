//
//  ExecuteTaskNow.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 14/01/2021.
//

import Foundation

enum ExecutetasknowWork: String, CaseIterable, Identifiable, CustomStringConvertible {
    case start
    case execute
    case completed
    case error

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized }
}

class ExecuteSingleTaskNow {
    weak var executetasknowstateDelegate: SingletaskNowState?
    weak var updateestimationcountDelegate: UpdateOutputprocessCountProtcol?

    var hiddenID: Int?
    var outputprocess: OutputfromProcess?
    var command: RsyncProcess?
    var localconfigurationsSwiftUI: ConfigurationsSwiftUI?
    var localschedulesSwiftUI: SchedulesSwiftUI?
    var structprofile: String?
    // Set if abort is executed
    private var setabort = false

    func executetasknow() {
        guard SharedReference.shared.process == nil else { return }
        if let hiddenID = hiddenID {
            outputprocess = OutputfromProcessRsync()
            if let arguments = localconfigurationsSwiftUI?.arguments4rsync(hiddenID: hiddenID, argtype: .arg) {
                command = RsyncProcess(arguments: arguments,
                                       config: localconfigurationsSwiftUI?.getconfiguration(hiddenID: hiddenID),
                                       processtermination: processtermination,
                                       filehandler: filehandler)
                command?.executeProcess(outputprocess: outputprocess)
            }
        }
    }

    func abort() {
        setabort = true
    }

    init(uuids: Set<UUID>,
         profile: String?,
         configurationsSwiftUI: ConfigurationsSwiftUI?,
         // TODO: fix schedules
         // schedulesSwiftUI: SchedulesSwiftUI?,
         executetaskstate: SingletaskNowState?,
         updateinprogresscount: UpdateOutputprocessCountProtcol?)
    {
        let configurations = configurationsSwiftUI?.getallconfigurations()?.filter { uuids.contains($0.id) }
        guard configurations?.count == 1 else { return }
        hiddenID = configurations?[0].hiddenID
        localconfigurationsSwiftUI = configurationsSwiftUI
        localschedulesSwiftUI = SchedulesSwiftUI(profile: profile, validhiddenIDs: configurationsSwiftUI?.validhiddenIDs ?? Set())
        executetasknowstateDelegate = executetaskstate
        structprofile = profile
        updateestimationcountDelegate = updateinprogresscount
        executetasknow()
    }

    deinit {
        // print("deinit ExecuteSingleTaskNow")
    }
}

extension ExecuteSingleTaskNow {
    func processtermination() {
        guard setabort == false else { return }
        updateestimationcountDelegate?.setoutput(data: outputprocess?.getOutput())
        if let hiddenID = hiddenID {
            executetasknowstateDelegate?.updatestate(state: .completed)
            let update = SingletaskPrimaryLogging(profile: structprofile,
                                                  hiddenID: hiddenID,
                                                  configurations: localconfigurationsSwiftUI?.getallconfigurations(),
                                                  validhiddenIDs: localconfigurationsSwiftUI?.validhiddenIDs ?? Set())
            update.setCurrentDateonConfiguration()
            update.addlogpermanentstore(outputprocess: outputprocess)
        }
        command = nil
    }

    func filehandler() {}
}

extension ExecuteSingleTaskNow: RsyncError {
    func rsyncerror() {
        executetasknowstateDelegate?.updatestate(state: .error)
    }
}
