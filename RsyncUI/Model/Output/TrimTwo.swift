//
//  TrimTwo.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 05/05/2021.
//

import Combine
import Foundation

enum Rsyncerror: LocalizedError {
    case rsyncerror

    var errorDescription: String? {
        switch self {
        case .rsyncerror:
            return NSLocalizedString("There are errors in output", comment: "rsync error") + "..."
        }
    }
}

final class TrimTwo {
    var subscriptions = Set<AnyCancellable>()
    var trimmeddata = [String]()
    var maxnumber: Int = 0
    var errordiscovered: Bool = false

    // Error handling
    func checkforrsyncerror(_ line: String) throws {
        let error = line.contains("rsync error:")
        if error {
            throw Rsyncerror.rsyncerror
        }
    }

    init(_ data: [String]) {
        data.publisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    // print("The publisher finished normally.")
                    return
                case let .failure(error):
                    self.propogateerror(error: error)
                }
            }, receiveValue: { [unowned self] line in
                if line.last != "/" {
                    trimmeddata.append(line)
                    do {
                        try checkforrsyncerror(line)
                    } catch let e {
                        // Only want one notification about error, not multiple
                        // Multiple can be a kind of race situation
                        if errordiscovered == false {
                            let error = e
                            _ = Logfile(data)
                            self.propogateerror(error: error)
                            errordiscovered = true
                        }
                    }
                }
                maxnumber = trimmeddata.count
            })
            .store(in: &subscriptions)
    }
}

extension TrimTwo: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
