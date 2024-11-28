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
    
    private func verifynetwork() async {
        var checkedserverandport = Array<TypeServerPort>()
        
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
                    checkedserverandport.append((server, sshport))
                    if checkedserverandport.contains(where: { $0.0 != server && $0.1 != sshport }) == true {
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
                        await verifynetwork()
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
