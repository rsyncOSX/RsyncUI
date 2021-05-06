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
    var outputprocess: OutputfromProcess?
    var config: Configuration?

    func startexecution() {
        if let arguments = self.arguments {
            let process = RsyncProcessCmdCombineClosure(arguments: arguments,
                                                        config: config,
                                                        processtermination: processtermination,
                                                        filehandler: filehandler)
            process.executeProcess(outputprocess: outputprocess)
        }
    }

    init(hiddenID: Int,
         configurationsSwiftUI: ConfigurationsSwiftUI?,
         outputprocess: OutputfromProcess?,
         processtermination: @escaping () -> Void,
         filehandler: @escaping () -> Void)
    {
        self.outputprocess = outputprocess
        self.processtermination = processtermination
        self.filehandler = filehandler
        arguments = configurationsSwiftUI?.arguments4rsync(hiddenID: hiddenID, argtype: .arg)
        config = configurationsSwiftUI?.getconfiguration(hiddenID: hiddenID)
    }

    deinit {
        // print("deinit ExecuteOneTask")
    }
}
