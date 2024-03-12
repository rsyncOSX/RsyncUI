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
    var config: SynchronizeConfiguration?

    func getconfig(_ hiddenID: Int, _ configurations: [SynchronizeConfiguration]) -> SynchronizeConfiguration? {
        if let index = configurations.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return configurations[index]
        }
        return nil
    }

    func startexecution() {
        if let arguments = arguments {
            let process = RsyncProcessFilehandler(arguments: arguments,
                                                  config: config,
                                                  processtermination: termination,
                                                  filehandler: filehandler)
            process.executeProcess()
        }
    }

    init(hiddenID: Int,
         configurations: [SynchronizeConfiguration],
         termination: @escaping ([String]?, Int?) -> Void,
         filehandler: @escaping (Int) -> Void)
    {
        self.termination = termination
        self.filehandler = filehandler
        config = getconfig(hiddenID, configurations)
        if let config = config {
            arguments = Argumentsforrsync().argumentsforrsync(config: config, argtype: .arg)
        }
    }
}
