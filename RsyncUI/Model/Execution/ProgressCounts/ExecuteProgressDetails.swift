//
//  ExecuteProgressDetails.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/02/2021.
//

import Foundation
import Observation
import OSLog

@Observable
final class ExecuteProgressDetails {
    @ObservationIgnored var hiddenIDatwork: Int = -1
    @ObservationIgnored var estimatedlist: [RemoteDataNumbers]?

    func taskisestimatedbyUUID(_ uuid: UUID) -> Bool {
        let answer = estimatedlist?.contains(where: { task in
            task.id == uuid
        }) ?? false ? true : false
        return answer
    }

    func getmaxcountbytask() -> Double {
        let max = estimatedlist?.filter { $0.hiddenID == hiddenIDatwork }
        if (max?.count ?? 0) == 1 {
            let num = Double(max?[0].outputfromrsync?.count ?? 0)
            Logger.process.info("ExecuteProgressDetails (getmaxcount): \(num, privacy: .public)")
            return Double(max?[0].outputfromrsync?.count ?? 0)
        } else {
            return 0
        }
    }

    deinit {
        // print("deinit ProgressDetails")
    }
}
