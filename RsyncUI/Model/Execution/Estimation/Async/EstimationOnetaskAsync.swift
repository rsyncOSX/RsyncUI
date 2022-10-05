//
//  EstimationOnetaskAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/10/2022.
//

import Foundation

@MainActor
final class EstimationOnetaskAsync {
    var arguments: [String]?
    var processtermination: ([String]?) -> Void
    var config: Configuration?
    var hiddenID: Int?

    func startestimation() async {
        if let arguments = arguments {
            let process = RsyncProcessAsync(arguments: arguments,
                                            config: config,
                                            processtermination: processtermination)
            await process.executeProcess()
        }
    }

    init(hiddenID: Int,
         configurationsSwiftUI: ConfigurationsSwiftUI?,
         local: Bool,
         processtermination: @escaping ([String]?) -> Void)
    {
        self.hiddenID = hiddenID
        self.processtermination = processtermination
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
