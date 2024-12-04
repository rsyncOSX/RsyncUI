//
//  ReadSynchronizeConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog

final class ReadSynchronizeConfigurationJSON: PropogateError {
    let path = Homepath()
    typealias TypeServerPort = (String, Int)

    func verifyremoteconnection(configurations: [SynchronizeConfiguration]?) async {
        var checkedserverandport = [TypeServerPort]()
        if let networkscheck = configurations?.filter({ task in
            task.offsiteServer.isEmpty == false
        }) {
            for i in 0 ..< networkscheck.count {
                let config = networkscheck[i]

                var sshport = 22
                if let port = config.sshport, port != -1 {
                    sshport = port
                } else if let port = SharedReference.shared.sshport, port != -1 {
                    sshport = port
                }
                do {
                    let server = config.offsiteServer
                    let itemforcheck = (server, sshport)
                    if checkedserverandport.contains(where: { $0 == itemforcheck }) == false {
                        checkedserverandport.append(itemforcheck)
                        Logger.process.info("ReadSynchronizeConfigurationJSON checking networkconnection server: \(server, privacy: .public) port: \(sshport, privacy: .public)")
                        _ = try await TCPconnections().asyncverifyTCPconnection(config.offsiteServer, port: sshport)
                    }

                } catch let e {
                    let error = e
                    propogateerror(error: error)
                }
            }
        }
    }

    func readjsonfilesynchronizeconfigurations(_ profile: String?) -> [SynchronizeConfiguration]? {
        var filename = ""
        if let profile, let path = path.fullpathmacserial {
            filename = path + "/" + profile + "/" + SharedReference.shared.fileconfigurationsjson
        } else {
            if let path = path.fullpathmacserial {
                filename = path + "/" + SharedReference.shared.fileconfigurationsjson
            }
        }
        let decodeimport = DecodeGeneric()
        do {
            if let data = try
                decodeimport.decodearraydatafileURL(DecodeSynchronizeConfiguration.self, fromwhere: filename)
            {
                Logger.process.info("ReadSynchronizeConfigurationJSON - \(profile ?? "default profile", privacy: .public): read configurations from permanent storage")
                let tasks = data.map { element in
                    SynchronizeConfiguration(element)
                }

                if SharedReference.shared.monitornetworkconnection {
                    Task {
                        await self.verifyremoteconnection(configurations: tasks)
                    }
                }

                return tasks
            }

        } catch let e {
            Logger.process.info("ReadSynchronizeConfigurationJSON - \(profile ?? "default profile", privacy: .public): some ERROR reading synchronize configurations from permanent storage")
            let error = e
            propogateerror(error: error)
        }
        return nil
    }

    deinit {
        Logger.process.info("ReadSynchronizeConfigurationJSON: deinit")
    }
}

// swiftlint:enable line_length
