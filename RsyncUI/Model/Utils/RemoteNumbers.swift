//
//  RemoteNumbers.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 10/11/2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

import Foundation

final class RemoteNumbers {
    private var output: [String]?
    private var splitnumbers: [String]?
    private var used1kblocks: Int?
    private var avail1kblocks: Int?
    private var capacity1kblocks: Int?
    private var percentavaliable: Double?

    private func split(_ str: String) -> [String] {
        return str.components(separatedBy: " ")
    }

    private func setnumbers() {
        guard output != nil else { return }
        guard (output?.count ?? 0) == 2 else { return }
        let splitnumberstring = split(output![1])
        splitnumbers = [String]()
        for i in 0 ..< splitnumberstring.count where splitnumberstring[i].isEmpty == false {
            self.splitnumbers?.append(splitnumberstring[i])
        }
        if let used1kblocks = Int(splitnumbers![2]) {
            self.used1kblocks = used1kblocks
        }
        if let avail1kblocks = Int(splitnumbers![3]) {
            self.avail1kblocks = avail1kblocks
        }
        if let capacity1kblocks = Int(splitnumbers![1]) {
            self.capacity1kblocks = capacity1kblocks
        }
        guard capacity1kblocks != nil, used1kblocks != nil else { return }
        percentavaliable = (1 - Double(used1kblocks!) / Double(capacity1kblocks!)) * 100
    }

    func getused() -> String {
        let used = (used1kblocks ?? 0 / 1024) / 1024
        return NumberFormatter.localizedString(from: NSNumber(value: used), number: NumberFormatter.Style.decimal)
    }

    func getavail() -> String {
        let avail = (avail1kblocks ?? 0 / 1024) / 1024
        return NumberFormatter.localizedString(from: NSNumber(value: avail), number: NumberFormatter.Style.decimal)
    }

    func getpercentavaliable() -> String {
        return String(format: "%.2f", percentavaliable ?? 0)
    }

    init(outputprocess: OutputProcess?) {
        output = outputprocess?.trimoutput(trim: .two)
        setnumbers()
    }
}
