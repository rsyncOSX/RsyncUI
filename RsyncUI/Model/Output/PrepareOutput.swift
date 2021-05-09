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
    var adjustedtrimdata = [String]()
    var splitlines: Bool = false

    // A split of lines are always after each other.
    // Line length is about 48/49 characters, a split might be like
    // drwx------             71 2019/07/02 07:53:37 300
    // drwx------             71 2019/07/02 07:53:37 30
    // 1
    // drwx------             72 2019/07/05 09:35:31 302
    //
    func alignsplitlines() {
        print("start max \(trimmeddata.count)")
        for i in 0 ..< trimmeddata.count - 1 {
            guard i < (trimmeddata.count - 1) else { return }
            if trimmeddata[i].count < 40 {
                // Must decide which two lines to merge
                if trimmeddata[i - 1].count > trimmeddata[i + 1].count {
                    // Merge i and i+1, remove i+1
                    let newline = trimmeddata[i] + trimmeddata[i + 1]
                    trimmeddata[i] = newline
                    trimmeddata.remove(at: i + 1)
                    print("removed row (Merge i and (i + 1), remove i+1) \(trimmeddata.count)")
                } else {
                    let newline = trimmeddata[i - 1] + trimmeddata[i]
                    trimmeddata[i - 1] = newline
                    trimmeddata.remove(at: i)
                    print("removed row (Merge (i - 1)  and i, remove i) \(trimmeddata.count)")
                }
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
                if line.count < 40, splitlines == false {
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
