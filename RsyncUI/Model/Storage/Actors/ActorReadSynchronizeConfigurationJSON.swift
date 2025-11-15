//
//  ActorReadSynchronizeConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog

actor ActorReadSynchronizeConfigurationJSON {
    typealias TypeServerPort = (String, Int)

    @concurrent
    nonisolated func verifyremoteconnection(configurations: [SynchronizeConfiguration]?, sharedsshport: Int?) async {
        let reporterror = ReportError()
        var checkedserverandport = [TypeServerPort]()

        if let networkscheck = configurations?.filter({ task in
            task.offsiteServer.isEmpty == false
        }) {
            for i in 0 ..< networkscheck.count {
                let config = networkscheck[i]

                var sshport = 22
                if let port = config.sshport, port != -1 {
                    sshport = port
                } else if let port = sharedsshport, port != -1 {
                    sshport = port
                }
                do {
                    let server = config.offsiteServer
                    let itemforcheck = (server, sshport)
                    if checkedserverandport.contains(where: { $0 == itemforcheck }) == false {
                        checkedserverandport.append(itemforcheck)
                        Logger.process.info("ActorReadSynchronizeConfigurationJSON: checking networkconnection server: \(server, privacy: .public) port: \(sshport, privacy: .public)")
                        _ = try await TCPconnections().asyncverifyTCPconnection(config.offsiteServer, port: sshport)
                    }

                } catch let e {
                    let server = config.offsiteServer
                    Logger.process.info("ActorReadSynchronizeConfigurationJSON: some ERROR checking networkconnection server: \(server, privacy: .public) port: \(sshport, privacy: .public)")
                    let error = e
                    await reporterror.propogateerror(error: error)
                }
            }
        }
    }

    @concurrent
    nonisolated func readjsonfilesynchronizeconfigurations(_ profile: String?,
                                                           _ rsyncversion3: Bool,
                                                           _ monitornetworkconnection: Bool,
                                                           _ sharedsshport: Int?) async -> [SynchronizeConfiguration]?
    {
        var filename = ""
        let path = await Homepath()

        Logger.process.info("ActorReadSynchronizeConfigurationJSON: readjsonfilesynchronizeconfigurations() MAIN THREAD: \(Thread.isMain, privacy: .public) but on \(Thread.current, privacy: .public)")

        if let profile, let fullpathmacserial = path.fullpathmacserial {
            filename = fullpathmacserial.appending("/") + profile.appending("/") + SharedConstants().fileconfigurationsjson
        } else {
            if let fullpathmacserial = path.fullpathmacserial {
                filename = fullpathmacserial.appending("/") + SharedConstants().fileconfigurationsjson
            }
        }
        let decodeimport = DecodeGeneric()
        do {
            if let data = try
                decodeimport.decodearraydatafileURL(DecodeSynchronizeConfiguration.self, fromwhere: filename)
            {
                if Thread.checkIsMainThread() {
                    Logger.process.info("ActorReadSynchronizeConfigurationJSON - \(profile ?? "default profile", privacy: .public): DECODE Running on main thread")
                } else {
                    Logger.process.info("ActorReadSynchronizeConfigurationJSON - \(profile ?? "default profile", privacy: .public): DECODE NOT on main thread, currently on \(Thread.current, privacy: .public)")
                }
                let tasks = data.compactMap { element in
                    // snapshot and syncremote tasks requiere version3.x of rsync
                    if element.task == "snapshot" || element.task == "syncremote" {
                        if rsyncversion3 {
                            return SynchronizeConfiguration(element)
                        }
                    } else {
                        return SynchronizeConfiguration(element)
                    }
                    return nil
                }

                if monitornetworkconnection {
                    Task {
                        await self.verifyremoteconnection(configurations: tasks, sharedsshport: sharedsshport)
                    }
                }

                return tasks
            }

        } catch let e {
            Logger.process.error("ActorReadSynchronizeConfigurationJSON - \(profile ?? "default profile", privacy: .public): some ERROR reading synchronize configurations from permanent storage")
            let error = e
            await path.propogateerror(error: error)
        }
        return nil
    }

    deinit {
        Logger.process.info("ActorReadSynchronizeConfigurationJSON: DEINIT")
    }
}

@MainActor
struct ReportError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }
}

// swiftlint:enable line_length
