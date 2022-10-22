//
//  ExecuteAlltasksAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/10/2022.
//

import Foundation

final class ExecuteAlltasksAsync: EstimateAlltasksAsync {
    @MainActor
    override func startestimation() async {
        guard stackoftasktobeestimated?.count ?? 0 > 0 else {
            updateestimationcountDelegate?.asyncestimationcomplete()
            return
        }
        let localhiddenID = stackoftasktobeestimated?.removeLast()
        guard localhiddenID != nil else { return }
        let arguments = localconfigurationsSwiftUI?.arguments4rsync(hiddenID: localhiddenID ?? 0, argtype: .arg)
        let config = localconfigurationsSwiftUI?.getconfiguration(hiddenID: localhiddenID ?? 0)
        guard arguments?.count ?? 0 > 0 else { return }
        let process = RsyncProcessAsync(arguments: arguments,
                                        config: config,
                                        processtermination: processtermination)
        await process.executeProcess()
    }
}
