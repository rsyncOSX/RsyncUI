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
            Logger.process.debugtthreadonly("GetversionofRsyncUI: getversionsofrsyncui()")
            let versions = DecodeGeneric()
            if let versionsofrsyncui =
                try await versions.decodearraydata(VersionsofRsyncUI.self,
                                                   fromwhere: Resources().getResource(resource: .urlJSON))
            {
                Logger.process.debugmesseageonly("CheckfornewversionofRsyncUI: \(versionsofrsyncui)")
                let runningversion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                let check = versionsofrsyncui.filter { runningversion.isEmpty ? true : $0.version == runningversion }
                if check.count > 0 {
                    Logger.process.debugmesseageonly("CheckfornewversionofRsyncUI: COMPLETED NEW VERSION FOUND")
                    return true
                } else {
                    Logger.process.debugmesseageonly("CheckfornewversionofRsyncUI: COMPLETED NO NEW VERSION")
                    return false
                }
            }
        } catch {
            Logger.process.warning("CheckfornewversionofRsyncUI: loading data failed)")
            return false
        }
        return false
    }

    @concurrent
    nonisolated func downloadlinkofrsyncui() async -> String? {
        do {
            Logger.process.debugtthreadonly("GetversionofRsyncUI: downloadlinkofrsyncui()")
            let versions = DecodeGeneric()
            if let versionsofrsyncui =
                try await versions.decodearraydata(VersionsofRsyncUI.self,
                                                   fromwhere: Resources().getResource(resource: .urlJSON))
            {
                Logger.process.debugmesseageonly("CheckfornewversionofRsyncUI: \(versionsofrsyncui)")
                let runningversion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                let check = versionsofrsyncui.filter { runningversion.isEmpty ? true : $0.version == runningversion }
                if check.count > 0 {
                    return check[0].url
                } else {
                    return nil
                }
            }
        } catch {
            Logger.process.warning("CheckfornewversionofRsyncUI: loading data failed)")
            return nil
        }
        return nil
    }
}
