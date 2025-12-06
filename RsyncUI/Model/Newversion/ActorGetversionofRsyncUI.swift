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
    nonisolated func getversionsofrsyncui() async -> Bool {
        do {
            let versions = DecodeGeneric()
            let versionsofrsyncui =
                try await versions.decodeArray(VersionsofRsyncUI.self,
                                               fromURL: Resources().getResource(resource: .urlJSON))

            Logger.process.debugMessageOnly("CheckfornewversionofRsyncUI: \(versionsofrsyncui)")
            let runningversion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            let check = versionsofrsyncui.filter { runningversion.isEmpty ? true : $0.version == runningversion }
            if check.count > 0 {
                return true
            } else {
                return false
            }

        } catch {
            Logger.process.warning("CheckfornewversionofRsyncUI: loading data failed)")
            return false
        }
    }

    @concurrent
    nonisolated func downloadlinkofrsyncui() async -> String? {
        do {
            let versions = DecodeGeneric()
            let versionsofrsyncui =
                try await versions.decodeArray(VersionsofRsyncUI.self,
                                               fromURL: Resources().getResource(resource: .urlJSON))

            Logger.process.debugMessageOnly("CheckfornewversionofRsyncUI: \(versionsofrsyncui)")
            let runningversion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            let check = versionsofrsyncui.filter { runningversion.isEmpty ? true : $0.version == runningversion }
            if check.count > 0 {
                return check[0].url
            } else {
                return nil
            }

        } catch {
            Logger.process.warning("CheckfornewversionofRsyncUI: loading data failed)")
            return nil
        }
    }
}
