//
//  ExecuteTaskNow.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 14/01/2021.
//
// swiftlint:disable line_length

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
    var outputprocess: OutputProcess?
    var command: RsyncProcessCmdCombine?
    var localconfigurationsSwiftUI: ConfigurationsSwiftUI?
    var localschedulesSwiftUI: SchedulesSwiftUI?
    var structprofile: String?
    // Set if abort is executed
    private var setabort = false

    func executetasknow() {
        guard SharedReference.shared.process == nil else { return }
        if let hiddenID = self.hiddenID {
            outputprocess = OutputProcessRsync()
            if let arguments = localconfigurationsSwiftUI?.arguments4rsync(hiddenID: hiddenID, argtype: .arg) {
                command = RsyncProcessCmdCombine(arguments: arguments,
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
         schedulesSwiftUI: SchedulesSwiftUI?,
         executetaskstate: SingletaskNowState?,
         updateinprogresscount: UpdateOutputprocessCountProtcol?)
    {
        let configurations = configurationsSwiftUI?.getallconfigurations()?.filter { uuids.contains($0.id) }
        guard configurations?.count == 1 else { return }
        hiddenID = configurations?[0].hiddenID
        localconfigurationsSwiftUI = configurationsSwiftUI
        localschedulesSwiftUI = schedulesSwiftUI
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
        if let hiddenID = self.hiddenID {
            executetasknowstateDelegate?.updatestate(state: .completed)
            let update = SingletaskPrimaryLogging(profile: structprofile,
                                                  hiddenID: hiddenID,
                                                  configurations: localconfigurationsSwiftUI?.getallconfigurations(),
                                                  scheduleConfigurations: localschedulesSwiftUI?.getschedules())
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
