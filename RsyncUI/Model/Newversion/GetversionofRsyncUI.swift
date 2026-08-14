//
//  GetversionofRsyncUI.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 02/07/2025.
//

import Foundation
import OSLog

actor GetversionofRsyncUI {
    static let shared = GetversionofRsyncUI()

    private var cached: [VersionsofRsyncUI]?

    private init() {}

    private func matchingVersions() async throws -> [VersionsofRsyncUI] {
        if let cached {
            return cached
        }

        guard let resourceURL = URL(string: Resources().getResource(resource: .urlJSON)) else {
            throw URLError(.badURL)
        }

        let all = try await SharedJSONStorageReader.shared.decodeArray(
            VersionsofRsyncUI.self,
            fromRemoteURL: resourceURL
        )
        Logger.process.debugThreadOnly("GetversionofRsyncUI: \(all)")
        let runningversion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let filtered = all.filter { runningversion.isEmpty ? true : $0.version == runningversion }
        cached = filtered
        return filtered
    }

    func getversionsofrsyncui() async -> Bool {
        do {
            return try await matchingVersions().isEmpty == false
        } catch {
            Logger.process.warning("GetversionofRsyncUI: loading data failed)")
            return false
        }
    }

    func downloadlinkofrsyncui() async -> String? {
        do {
            return try await matchingVersions().first?.url
        } catch {
            Logger.process.warning("GetversionofRsyncUI: loading data failed)")
            return nil
        }
    }
}
