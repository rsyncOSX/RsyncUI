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
    // var outputprocess: OutputfromProcess?
    var command: RsyncProcessAsync?
    var localconfigurationsSwiftUI: ConfigurationsSwiftUI?
    var structprofile: String?
    // Set if abort is executed
    private var setabort = false

    @MainActor
    func executetasknow() async {
        guard SharedReference.shared.process == nil else { return }
        if let hiddenID = hiddenID {
            // outputprocess = OutputfromProcessRsync()
            if let arguments = localconfigurationsSwiftUI?.arguments4rsync(hiddenID: hiddenID, argtype: .arg) {
                command = RsyncProcessAsync(arguments: arguments,
                                            config: localconfigurationsSwiftUI?.getconfiguration(hiddenID: hiddenID),
                                            processtermination: processtermination)
                await command?.executeProcess()
            }
        }
    }

    func abort() {
        setabort = true
    }

    init(uuids: Set<UUID>,
         profile: String?,
         configurationsSwiftUI: ConfigurationsSwiftUI?,
         executetaskstate: SingletaskNowState?,
         updateinprogresscount: UpdateOutputprocessCountProtcol?) async {
        let configurations = configurationsSwiftUI?.getallconfigurations()?.filter { uuids.contains($0.id) }
        guard configurations?.count == 1 else { return }
        hiddenID = configurations?[0].hiddenID
        localconfigurationsSwiftUI = configurationsSwiftUI
        executetasknowstateDelegate = executetaskstate
        structprofile = profile
        updateestimationcountDelegate = updateinprogresscount
        await executetasknow()
    }

    deinit {
        // print("deinit ExecuteSingleTaskNow")
    }
}

extension ExecuteSingleTaskNow {
    func processtermination(outputfromrsync: [String]?, hiddenID: Int?) {
        guard setabort == false else { return }
        updateestimationcountDelegate?.setoutput(data: outputfromrsync)
        if let hiddenID = hiddenID {
            executetasknowstateDelegate?.updatestate(state: .completed)
            let update = SingletaskPrimaryLogging(profile: structprofile,
                                                  hiddenID: hiddenID,
                                                  configurations: localconfigurationsSwiftUI?.getallconfigurations(),
                                                  validhiddenIDs: localconfigurationsSwiftUI?.validhiddenIDs ?? Set())
            update.setCurrentDateonConfiguration()
            update.addlogpermanentstore(outputrsync: outputfromrsync)
        }
        command = nil
    }
}

extension ExecuteSingleTaskNow: RsyncError {
    func rsyncerror() {
        executetasknowstateDelegate?.updatestate(state: .error)
    }
}
