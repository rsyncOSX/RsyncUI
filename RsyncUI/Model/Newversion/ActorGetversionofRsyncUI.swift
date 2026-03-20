//
//  ActorGetversionofRsyncUI.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 02/07/2025.
//

import DecodeEncodeGeneric
import OSLog

actor ActorGetversionofRsyncUI {
    @concurrent
    nonisolated private func fetchMatchingVersions() async throws -> [VersionsofRsyncUI] {
        let all = try await DecodeGeneric().decodeArray(VersionsofRsyncUI.self,
                                                        fromURL: Resources().getResource(resource: .urlJSON))
        Logger.process.debugMessageOnly("CheckfornewversionofRsyncUI: \(all)")
        let runningversion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        return all.filter { runningversion.isEmpty ? true : $0.version == runningversion }
    }

    @concurrent
    nonisolated func getversionsofrsyncui() async -> Bool {
        do {
            return try await fetchMatchingVersions().isEmpty == false
        } catch {
            Logger.process.warning("CheckfornewversionofRsyncUI: loading data failed)")
            return false
        }
    }

    @concurrent
    nonisolated func downloadlinkofrsyncui() async -> String? {
        do {
            return try await fetchMatchingVersions().first?.url
        } catch {
            Logger.process.warning("CheckfornewversionofRsyncUI: loading data failed)")
            return nil
        }
    }
}
