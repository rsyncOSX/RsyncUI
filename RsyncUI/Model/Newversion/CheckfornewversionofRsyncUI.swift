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

    func dismissnotify() {
        Task {
            try await Task.sleep(seconds: 2)
            self.notifynewversion = false
        }
    }

    func getversionsofrsyncui() async {
        do {
            let versions = DecodeGeneric()
            if let versionsofrsyncui =
                try await versions.decodearraydata(VersionsofRsyncUI.self,
                                                   fromwhere: Resources().getResource(resource: .urlJSON))
            {
                Logger.process.info("CheckfornewversionofRsyncUI: \(versionsofrsyncui, privacy: .public)")
                let runningversion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                let check = versionsofrsyncui.filter { runningversion.isEmpty ? true : $0.version == runningversion }
                if check.count > 0 {
                    notifynewversion = true
                    SharedReference.shared.URLnewVersion = check[0].url
                } else {
                    notifynewversion = false
                }
                downloadavaliable = notifynewversion
            }
        } catch {
            Logger.process.warning("CheckfornewversionofRsyncUI: loading data failed)")
            notifynewversion = false
        }
    }
}
