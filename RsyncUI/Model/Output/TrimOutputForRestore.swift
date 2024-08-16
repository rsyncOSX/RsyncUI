//
//  TrimOutputForRestore.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 05/05/2021.
//

import Combine
import Foundation

@MainActor
final class TrimOutputForRestore: PropogateError {
    var subscriptions = Set<AnyCancellable>()
    var trimmeddata = [String]()

    init(_ data: [String]) {
        data.publisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    return
                case let .failure(error):
                    self.propogateerror(error: error)
                }
            }, receiveValue: { [unowned self] line in
                let substr = line.dropFirst(10).trimmingCharacters(in: .whitespacesAndNewlines)
                let str = substr.components(separatedBy: " ").dropFirst(3).joined(separator: " ")
                if str.isEmpty == false,
                   str.contains(".DS_Store") == false,
                   str.contains("bytes") == false,
                   str.contains("speedup") == false
                {
                    trimmeddata.append("./" + str)
                }
            })
            .store(in: &subscriptions)
    }
}
