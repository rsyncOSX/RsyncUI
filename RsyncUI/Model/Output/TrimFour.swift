//
//  TrimFour.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 05/05/2021.
//

import Foundation
import Combine

final class TrimFour {
    
    var subscriptions = Set<AnyCancellable>()
    var trimmeddata = [String]()
    
    init(_ data: [String]) {
        data.publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    // print("The publisher finished normally.")
                    return
                case let .failure(error):
                    self.propogateerror(error: error)
                }
            }, receiveValue: { [unowned self] line in
                let substr = line.dropFirst(10).trimmingCharacters(in: .whitespacesAndNewlines)
                let str = substr.components(separatedBy: " ").dropFirst(1).dropLast(2).joined(separator: " ")
                if str.count > 4, str.contains(".DS_Store") == false {
                    self.trimmeddata.append(str)
                }
            })
            .store(in: &subscriptions)
    }
}

extension TrimFour: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}

