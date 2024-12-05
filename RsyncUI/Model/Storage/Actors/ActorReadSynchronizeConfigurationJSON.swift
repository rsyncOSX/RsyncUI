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

    func verifyremoteconnection(configurations: [SynchronizeConfiguration]?, sharedsshport: Int?) async {
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
                        Logger.process.info("ActorReadSynchronizeConfigurationJSON checking networkconnection server: \(server, privacy: .public) port: \(sshport, privacy: .public)")
                        _ = try await TCPconnections().asyncverifyTCPconnection(config.offsiteServer, port: sshport)
                    }

                } catch {
                    let server = config.offsiteServer
                    Logger.process.info("ActorReadSynchronizeConfigurationJSON: some ERROR checking networkconnection server: \(server, privacy: .public) port: \(sshport, privacy: .public)")
                }
            }
        }
    }

    func readjsonfilesynchronizeconfigurations(_ profile: String?,
                                               _ monitornetworkconnection: Bool,
                                               _ sharedsshport: Int?,
                                               _ filenameconfigurations: String) async -> [SynchronizeConfiguration]?
    {
        var filename = ""
        let path = await Homepath()

        Logger.process.info("readjsonfilesynchronizeconfigurations(): on main thread: \(Thread.isMain)")

        if let profile, profile != "Default profile", let path = path.fullpathmacserial {
            filename = path + "/" + profile + "/" + filenameconfigurations
        } else {
            if let path = path.fullpathmacserial {
                filename = path + "/" + filenameconfigurations
            }
        }
        let decodeimport = await DecodeGeneric()
        do {
            if let data = try
                await decodeimport.decodearraydatafileURL(DecodeSynchronizeConfiguration.self, fromwhere: filename)
            {
                Logger.process.info("ActorReadSynchronizeConfigurationJSON - \(profile ?? "default profile", privacy: .public): read configurations from permanent storage")
                let tasks = data.map { element in
                    SynchronizeConfiguration(element)
                }

                if monitornetworkconnection {
                    Task {
                        await self.verifyremoteconnection(configurations: tasks, sharedsshport: sharedsshport)
                    }
                }

                return tasks
            }

        } catch {
            Logger.process.info("ActorReadSynchronizeConfigurationJSON - \(profile ?? "default profile", privacy: .public): some ERROR reading synchronize configurations from permanent storage")
            return nil
        }
        return nil
    }

    deinit {
        Logger.process.info("ActorReadSynchronizeConfigurationJSON: deinit")
    }
}

// swiftlint:enable line_length
