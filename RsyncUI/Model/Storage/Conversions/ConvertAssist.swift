//
//  ConvertAssist.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 02/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
// swiftlint:disable cyclomatic_complexity trailing_comma

import Foundation

struct ConvertAssist {
    var assist: [NSDictionary]?

    init(assistassets: [Set<String>]?) {
        guard assistassets != nil else { return }
        assist = [NSDictionary]()
        for i in 0 ..< (assistassets?.count ?? 0) {
            switch i {
            case 0:
                for val in assistassets![0] {
                    let dict: NSDictionary = [
                        DictionaryStrings.remotecomputers.rawValue: val,
                    ]
                    assist?.append(dict)
                }
            case 1:
                for val in assistassets![1] {
                    let dict: NSDictionary = [
                        DictionaryStrings.remoteusers.rawValue: val,
                    ]
                    assist?.append(dict)
                }
            case 2:
                for val in assistassets![2] {
                    let dict: NSDictionary = [
                        DictionaryStrings.remotehome.rawValue: val,
                    ]
                    assist?.append(dict)
                }
            case 3:
                for val in assistassets![3] {
                    let dict: NSDictionary = [
                        DictionaryStrings.catalogs.rawValue: val,
                    ]
                    assist?.append(dict)
                }
            case 4:
                for val in assistassets![4] {
                    let dict: NSDictionary = [
                        DictionaryStrings.localhome.rawValue: val,
                    ]
                    assist?.append(dict)
                }
            default:
                return
            }
        }
    }
}
