//
//  SingleTask.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 20.06.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
//  swiftlint:disable opening_brace line_length

import Foundation

enum SingleTaskWork: String, CaseIterable, Identifiable, CustomStringConvertible {
    case start
    case estimated
    case execute
    case abort
    case estimate
    case completed
    case error

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized }
}

final class ExecuteSingleTask {
    var hiddenID: Int?
    var outputprocess: OutputProcess?
    var workqueu: SingleTaskWorkQueu?
    var command: RsyncProcessCmdCombineClosure?
    var structconfigurations: ConfigurationsSwiftUI?
    var structschedules: SchedulesSwiftUI?
    var structprofile: String?
    var uuid = Set<UUID>()
    // Set if abort is executed
    private var setabort = false

    weak var singletaskstateDelegate: SingleTaskState?
    weak var updateoutputprocesscountDelegate: UpdateOutputprocessCountProtcol?

    func estimate() {
        guard SharedReference.shared.process == nil else { return }
        // Debug print
        // printdebugdata(uuid)
        // Debug print
        if let hiddenID = self.hiddenID {
            outputprocess = OutputProcessRsync()
            if let arguments = structconfigurations?.arguments4rsync(hiddenID: hiddenID, argtype: .argdryRun),
               let config = structconfigurations?.getconfiguration(hiddenID: hiddenID)
            {
                command = RsyncProcessCmdCombineClosure(arguments: arguments,
                                                        config: config,
                                                        processtermination: processtermination,
                                                        filehandler: filehandler)
                command?.executeProcess(outputprocess: outputprocess)
            }
        }
    }

    func execute() {
        guard SharedReference.shared.process == nil else { return }
        // Debug print
        // printdebugdata(uuid)
        // Debug print
        if let hiddenID = self.hiddenID {
            outputprocess = OutputProcessRsync()
            if let arguments = structconfigurations?.arguments4rsync(hiddenID: hiddenID, argtype: .arg) {
                command = RsyncProcessCmdCombineClosure(arguments: arguments,
                                                        config: structconfigurations?.getconfiguration(hiddenID: hiddenID),
                                                        processtermination: processtermination,
                                                        filehandler: filehandler)
                command?.executeProcess(outputprocess: outputprocess)
            }
        }
    }

    func abort() {
        setabort = true
    }

    // Needs ConfigurationsSwiftUI to get arguments.
    // Index to selected configuration
    init(uuids: Set<UUID>,
         profile: String?,
         configurationsSwiftUI: ConfigurationsSwiftUI?,
         schedulesSwiftUI: SchedulesSwiftUI?,
         singletaskstate: SingleTaskState?,
         updateinprogresscount: UpdateOutputprocessCountProtcol?)
    {
        uuid = uuids
        structconfigurations = configurationsSwiftUI
        structschedules = schedulesSwiftUI
        singletaskstateDelegate = singletaskstate
        structprofile = profile
        updateoutputprocesscountDelegate = updateinprogresscount
        let configurations = configurationsSwiftUI?.getallconfigurations()?.filter { uuids.contains($0.id) }
        guard configurations?.count == 1 else { return }
        hiddenID = configurations?[0].hiddenID
        workqueu = SingleTaskWorkQueu()
    }

    deinit {
        // print("deinit ExecuteSingleTask")
    }

    // debug
    func printdebugdata(_ uuids: Set<UUID>) {
        let configurations = structconfigurations?.getallconfigurations()?.filter { uuids.contains($0.id) }
        print("EXECUTION of singleTask state: \(singletaskstateDelegate?.singletaskstate ?? .start) and \(configurations?.count ?? 0) number of configurations")
        if uuids.count != (configurations?.count ?? 0) {
            print("PROBLEM: clearing old uuids not done properly")
        }
    }
}

extension ExecuteSingleTask {
    func processtermination() {
        guard setabort == false else { return }
        if let workload = workqueu,
           let hiddenID = self.hiddenID
        {
            // Sending output from rsync to the observed object
            updateoutputprocesscountDelegate?.setoutput(data: outputprocess?.getOutput())
            switch workload.pop() {
            case .estimated: // estimation completed
                singletaskstateDelegate?.updatestate(state: workqueu?.peek() ?? .start)
                updateoutputprocesscountDelegate?.setmaxcount(num: outputprocess?.getMaxcount() ?? 0)
            case .error:
                workqueu = nil
            case .execute: // execution completed
                let update = SingletaskPrimaryLogging(profile: structprofile,
                                                      hiddenID: hiddenID,
                                                      configurations: structconfigurations?.getallconfigurations(),
                                                      scheduleConfigurations: structschedules?.getschedules())
                update.setCurrentDateonConfiguration()
                update.addlogpermanentstore(outputprocess: outputprocess)
                singletaskstateDelegate?.updatestate(state: .completed)
            default:
                return
            }
        }
        command = nil
    }

    func filehandler() {
        if workqueu?.peek() == .execute {
            updateoutputprocesscountDelegate?.updateinprogresscount(num: Double(outputprocess?.count() ?? 0))
        }
    }
}

extension ExecuteSingleTask: RsyncError {
    func rsyncerror() {
        singletaskstateDelegate?.updatestate(state: .error)
    }
}

final class SingleTaskWorkQueu {
    // Work Queue
    private var work: [SingleTaskWork]?

    // Returns the top most element.
    // Top element is read only
    func peek() -> SingleTaskWork {
        return work?[0] ?? .estimate
    }

    // Returns the top most element.
    // Top element is removed
    func pop() -> SingleTaskWork {
        return work?.removeFirst() ?? .estimate
    }

    // rsync error
    // Pushing error token ontop of stack
    func error() {
        work?.insert(.error, at: 0)
    }

    // Single run
    init() {
        work = [SingleTaskWork]()
        work?.append(.estimated)
        work?.append(.execute)
        work?.append(.completed)
    }

    deinit {
        // print("deinit SingleTaskWorkQueu")
    }
}
