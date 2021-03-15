//
//  EstimationOnetask.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/01/2021.
//

import Foundation

final class EstimationOnetask {
    var arguments: [String]?
    var processtermination: () -> Void
    var filehandler: () -> Void
    var outputprocess: OutputProcess?

    func startestimation() {
        if let arguments = self.arguments {
            let process = RsyncProcessCmdCombineClosure(arguments: arguments,
                                                        config: nil,
                                                        processtermination: processtermination,
                                                        filehandler: filehandler)
            process.executeProcess(outputprocess: outputprocess)
        }
    }

    init(hiddenID: Int,
         configurationsSwiftUI: ConfigurationsSwiftUI?,
         outputprocess: OutputProcess?,
         local: Bool,
         processtermination: @escaping () -> Void,
         filehandler: @escaping () -> Void)
    {
        self.outputprocess = outputprocess
        self.processtermination = processtermination
        self.filehandler = filehandler
        // local is true for getting info about local catalogs.
        // used when shwoing diff local files vs remote files
        if local {
            arguments = configurationsSwiftUI?.arguments4rsync(hiddenID: hiddenID, argtype: .argdryRunlocalcataloginfo)
        } else {
            arguments = configurationsSwiftUI?.arguments4rsync(hiddenID: hiddenID, argtype: .argdryRun)
        }
    }

    deinit {
        // print("deinit EstimationOnetask")
    }
}
