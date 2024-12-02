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

@MainActor
final class ReadSynchronizeConfigurationJSON: PropogateError {
    var configurations: [SynchronizeConfiguration]?
    let path = Homepath()

    typealias TypeServerPort = (String, Int)

    private func verifyremoteconnection() async {
        var checkedserverandport = [TypeServerPort]()
        if let networkscheck = configurations?.filter({ task in
            task.offsiteServer.isEmpty == false
        }) {
            Logger.process.info("verifyremoteconnection(): on main thread: \(Thread.isMain)")
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

    private func importjsonfile(_ filenamedatastore: String, profile: String?) {
        let decodeimport = DecodeGeneric()
        do {
            if let data = try
                decodeimport.decodearraydatafileURL(DecodeSynchronizeConfiguration.self, fromwhere: filenamedatastore)
            {
                configurations = data.map { element in
                    SynchronizeConfiguration(element)
                }

                Logger.process.info("ReadSynchronizeConfigurationJSON - \(profile ?? "default profile", privacy: .public): read configurations from permanent storage")

                if SharedReference.shared.monitornetworkconnection {
                    Task {
                        await self.verifyremoteconnection()
                    }
                }
            }

        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    init(_ profile: String?) {
        var filename = ""
        if let profile, let path = path.fullpathmacserial {
            filename = path + "/" + profile + "/" + SharedReference.shared.fileconfigurationsjson
        } else {
            if let path = path.fullpathmacserial {
                filename = path + "/" + SharedReference.shared.fileconfigurationsjson
            }
        }
        importjsonfile(filename, profile: profile)
    }

    deinit {
        Logger.process.info("ReadSynchronizeConfigurationJSON: deinit")
    }
}

// swiftlint:enable line_length
