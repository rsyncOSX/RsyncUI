//
//  ExecuteOneTask.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 22/01/2021.
//

import Foundation

@MainActor
final class ExecuteOneTask {
    var arguments: [String]?
    var processtermination: ([String]?, Int?) -> Void
    var filehandler: (Int) -> Void
    var config: SynchronizeConfiguration?

    func getconfig(_ hiddenID: Int, _ configurations: [SynchronizeConfiguration]) -> SynchronizeConfiguration? {
        if let index = configurations.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return configurations[index]
        }
        return nil
    }

    func startexecution() {
        if let arguments {
            let process = ProcessRsync(arguments: arguments,
                                       config: config,
                                       processtermination: processtermination,
                                       filehandler: filehandler)
            process.executeProcess()
        }
    }

    init(hiddenID: Int,
         configurations: [SynchronizeConfiguration],
         processtermination: @escaping ([String]?, Int?) -> Void,
         filehandler: @escaping (Int) -> Void)
    {
        self.processtermination = processtermination
        self.filehandler = filehandler
        config = getconfig(hiddenID, configurations)
        if let config {
            arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: false,
                                                                                  forDisplay: false)
        }
    }
}
