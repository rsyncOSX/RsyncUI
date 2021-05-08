//
//  PrepareOutput.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 08/05/2021.
//

import Combine
import Foundation

final class PrepareOutput {
    var subscriptions = Set<AnyCancellable>()
    var trimmeddata = [String]()
    var splitlines: Bool = false

    // A split of lines are always after eachother.
    // Line length is 48/49 characters
    func alignsplitlines() {
        for i in 0 ..< trimmeddata.count - 1 {
            if trimmeddata[i].count < 40 {
                let newline = trimmeddata[i] + trimmeddata[i + 1]
                trimmeddata[i] = newline
                trimmeddata.remove(at: i + 1)
            }
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
                if line.count < 30, splitlines == false {
                    splitlines = true
                }
                trimmeddata.append(line)
            })
            .store(in: &subscriptions)
    }
}

extension PrepareOutput: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
