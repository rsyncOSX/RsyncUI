//
//  ExecuteOnetaskAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/10/2022.
//

import Foundation

final class ExecuteOnetaskAsync: EstimateOnetaskAsync {
    @MainActor
    override func startestimation() async {
        let arguments = localconfigurationsSwiftUI?.arguments4rsync(hiddenID: localhiddenID ?? 0, argtype: .arg)
        let config = localconfigurationsSwiftUI?.getconfiguration(hiddenID: localhiddenID ?? 0)
        guard arguments?.count ?? 0 > 0 else { return }
        let process = RsyncProcessAsync(arguments: arguments,
                                        config: config,
                                        processtermination: processtermination,
                                        newlineisread: newlineisread)
        await process.executeProcess()
    }
}
