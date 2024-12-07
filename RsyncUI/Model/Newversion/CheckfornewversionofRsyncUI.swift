//
//  CheckfornewversionofRsyncUI.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/12/2022.
//

import DecodeEncodeGeneric
import Foundation
import Observation
import OSLog

struct VersionsofRsyncUI: Codable {
    let url: String?
    let version: String?

    enum CodingKeys: String, CodingKey {
        case url
        case version
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        url = try values.decodeIfPresent(String.self, forKey: .url)
        version = try values.decodeIfPresent(String.self, forKey: .version)
    }
}

@Observable @MainActor
final class CheckfornewversionofRsyncUI {
    var notifynewversion: Bool = false
    var downloadavaliable: Bool = false
}

actor Getversionofrsync {
    
    func getversionsofrsyncui() async -> Bool {
        do {
            Logger.process.info("getversionsofrsyncui(): on main thread: \(Thread.isMain)")
            let versions = await DecodeGeneric()
            if let versionsofrsyncui =
                try await versions.decodearraydata(VersionsofRsyncUI.self,
                                                   fromwhere: Resources().getResource(resource: .urlJSON))
            {
                Logger.process.info("CheckfornewversionofRsyncUI: \(versionsofrsyncui, privacy: .public)")
                let runningversion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                let check = versionsofrsyncui.filter { runningversion.isEmpty ? true : $0.version == runningversion }
                if check.count > 0 {
                    return  true
                    // SharedReference.shared.URLnewVersion = check[0].url
                } else {
                    return false
                }
            }
        } catch {
            Logger.process.warning("CheckfornewversionofRsyncUI: loading data failed)")
            return false
        }
        return false
    }
    
    func downloadlinkofrsyncui() async throws -> String? {
        let versions = await DecodeGeneric()
        if let versionsofrsyncui =
            try await versions.decodearraydata(VersionsofRsyncUI.self,
                                               fromwhere: Resources().getResource(resource: .urlJSON))
        {
            let runningversion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            let check = versionsofrsyncui.filter { runningversion.isEmpty ? true : $0.version == runningversion }
            if check.count > 0 {
                return  check[0].url
            } else {
                return nil
            }
        }
        return nil
    }
}
