//
//  ExecuteOneTask.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 22/01/2021.
//

import Foundation

final class ExecuteOneTask {
    var arguments: [String]?
    var termination: ([String]?, Int?) -> Void
    var filehandler: (Int) -> Void
    var config: Configuration?

    func startexecution() {
        if let arguments = arguments {
            if config?.pretask?.isEmpty == false, config?.executepretask == 1 {
                let processshellout = RsyncProcessShellOut(arguments: arguments,
                                                           config: config,
                                                           processtermination: termination,
                                                           filehandler: filehandler)
                processshellout.executeProcess()
            } else {
                let process = RsyncProcess(arguments: arguments,
                                           config: config,
                                           processtermination: termination,
                                           filehandler: filehandler)
                process.executeProcess()
            }
        }
    }

    init(hiddenID: Int,
         configurations: RsyncUIconfigurations?,
         termination: @escaping ([String]?, Int?) -> Void,
         filehandler: @escaping (Int) -> Void)
    {
        self.termination = termination
        self.filehandler = filehandler
        config = configurations?.getconfig(hiddenID: hiddenID)
        if let config = config {
            arguments = Argumentsforrsync().argumentsforrsync(config: config, argtype: .arg)
        }
    }
}
