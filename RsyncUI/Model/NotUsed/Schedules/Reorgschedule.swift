//
//  Reorgschedule.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 21/11/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation

class Reorgschedule {
    func uniquelements<T: Hashable>(data: [T]) -> [T] {
        var elements = [T]()
        for i in 0 ..< data.count {
            elements.append(data[i])
        }
        return elements.unique()
    }

    func mergerecords<T: Hashable>(data: [T]?) -> [T]? {
        if let data = data {
            var mergedelements = [T]()
            let uniqueelements = uniquelements(data: data)
            for i in 0 ..< uniqueelements.count {
                let element = uniqueelements[i]
                let filter = data.filter { $0 == element }
                switch filter.count {
                case 0:
                    return nil
                case 1:
                    mergedelements.append(element)
                default:
                    mergedelements.append(element)
                    let index = mergedelements.count - 1
                    var mergedrecord = mergedelements[index] as? ConfigurationSchedule
                    for j in 1 ..< filter.count {
                        if let record = filter[j] as? ConfigurationSchedule {
                            for k in 0 ..< (record.logrecords?.count ?? 0) {
                                mergedrecord?.logrecords?.append((record.logrecords?[k])!)
                            }
                        }
                    }
                    if let mergedrecord = mergedrecord as? T {
                        mergedelements[index] = mergedrecord
                    }
                }
            }
            return mergedelements
        }
        return nil
    }
}

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var alreadyAdded = Set<Iterator.Element>()
        return filter { alreadyAdded.insert($0).inserted }
    }
}
