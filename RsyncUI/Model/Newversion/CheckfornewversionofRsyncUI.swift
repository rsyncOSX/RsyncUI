//
//  CheckfornewversionofRsyncUI.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/12/2022.
//

import Foundation

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

struct GetversionsofRsyncUI {
    let urlSession = URLSession.shared
    let jsonDecoder = JSONDecoder()

    func getversionsofrsyncuibyurl() async throws -> [VersionsofRsyncUI]? {
        if let url = URL(string: Resources().getResource(resource: .urlJSON)) {
            let (data, _) = try await urlSession.data(from: url)
            return try jsonDecoder.decode([VersionsofRsyncUI].self, from: data)
        } else {
            return nil
        }
    }
}

@MainActor
final class CheckfornewversionofRsyncUI: ObservableObject {
    @Published var notifynewversion: Bool = false

    func getversionsofrsyncui() async {
        do {
            let versions = GetversionsofRsyncUI()
            if let versionsofrsyncui = try await versions.getversionsofrsyncuibyurl() {
                let runningversion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                let check = versionsofrsyncui.filter { runningversion.isEmpty ? true : $0.version == runningversion }
                if check.count > 0 {
                    notifynewversion = true
                    SharedReference.shared.URLnewVersion = check[0].url
                } else {
                    notifynewversion = false
                }
            }

        } catch {
            notifynewversion = false
        }
    }
}
