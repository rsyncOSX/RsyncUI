//
//  ExecuteOneTask.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 22/01/2021.
//

import Foundation

final class ExecuteOneTask {
    var arguments: [String]?
    var processtermination: () -> Void
    var filehandler: () -> Void
    var outputprocess: OutputProcess?

    func startexecution() {
        if let arguments = self.arguments {
            let process = RsyncProcessCmdCombine(arguments: arguments,
                                                 config: nil,
                                                 processtermination: processtermination,
                                                 filehandler: filehandler)
            process.executeProcess(outputprocess: outputprocess)
        }
    }

    init(hiddenID: Int,
         configurationsSwiftUI: ConfigurationsSwiftUI?,
         outputprocess: OutputProcess?,
         processtermination: @escaping () -> Void,
         filehandler: @escaping () -> Void)
    {
        self.outputprocess = outputprocess
        self.processtermination = processtermination
        self.filehandler = filehandler
        arguments = configurationsSwiftUI?.arguments4rsync(hiddenID: hiddenID, argtype: .arg)
    }

    deinit {
        // print("deinit ExecuteOneTask")
    }
}
