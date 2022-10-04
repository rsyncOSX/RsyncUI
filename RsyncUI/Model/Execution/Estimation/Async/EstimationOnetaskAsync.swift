//
//  EstimationOnetaskAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/10/2022.
//

import Foundation

final class EstimationOnetaskAsync {
    var arguments: [String]?
    var processtermination: () -> Void
    var filehandler: () -> Void
    var outputprocess: OutputfromProcess?
    var config: Configuration?

    func startestimation() {
        if let arguments = arguments {
            let process = RsyncProcess(arguments: arguments,
                                       config: config,
                                       processtermination: processtermination,
                                       filehandler: filehandler)
            process.executeProcess(outputprocess: outputprocess)
        }
    }

    init(hiddenID: Int,
         configurationsSwiftUI: ConfigurationsSwiftUI?,
         outputprocess: OutputfromProcess?,
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
        config = configurationsSwiftUI?.getconfiguration(hiddenID: hiddenID)
    }

    deinit {
        // print("deinit EstimationOnetask")
    }
}
