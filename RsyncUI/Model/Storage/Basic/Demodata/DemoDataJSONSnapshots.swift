//
//  DemoDataJSONSnapshots.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 16/02/2024.
//

import Foundation

class DemoDataJSONSnapshots {
    let urlSession = URLSession.shared
    let jsonDecoder = JSONDecoder()
    var snapshotdata: [String]?

    var snapshotsJSON: String =
        "https://raw.githubusercontent.com/rsyncOSX/RsyncUI/master/samplejsondata/snapshotsV2.json"

    // let snapshots = await getdemodata.getsnapshots()

    private func getsnapshotsJSON() async throws -> [DecodeSnapshot]? {
        if let url = URL(string: snapshotsJSON) {
            let (data, _) = try await urlSession.data(from: url)
            return try jsonDecoder.decode([DecodeSnapshot].self, from: data)
        } else {
            return nil
        }
    }

    func getsnapshots() async -> [String]? {
        do {
            if let data = try await getsnapshotsJSON() {
                var mylogrecords = [String]()
                for i in 0 ..< data.count {
                    mylogrecords.append(data[i].line ?? "")
                }
                return mylogrecords
            }
        } catch {
            return nil
        }
        return nil
    }
}

struct DecodeSnapshot: Codable, Hashable {
    let line: String?

    enum CodingKeys: String, CodingKey {
        case line
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        line = try values.decodeIfPresent(String.self, forKey: .line)
    }
}
