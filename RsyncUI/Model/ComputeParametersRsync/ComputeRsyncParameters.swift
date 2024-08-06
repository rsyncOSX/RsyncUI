//
//  ComputeRsyncParameters.swift
//
//  Created by Thomas Evensen on 08/02/16.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
// swiftlint:disable cyclomatic_complexity type_body_length opening_brace

import Foundation

@MainActor
class ComputeRsyncParameters {
    var stats: Bool?
    var arguments: [String]?
    var localCatalog: String?
    var offsiteCatalog: String?
    var offsiteUsername: String?
    var offsiteServer: String?
    var remoteargs: String?
    var linkdestparam: String?

    func setParameters1To6(config: SynchronizeConfiguration, forDisplay: Bool, verify: Bool) {
        let parameter1: String? = if verify { "--checksum" } else
        { config.parameter1 }
        let parameter2: String = config.parameter2
        let parameter3: String = config.parameter3
        let parameter4: String = config.parameter4
        let parameter5: String = config.parameter5
        let parameter6: String = config.parameter6
        let offsiteServer: String = config.offsiteServer
        arguments?.append(parameter1 ?? "")
        if verify {
            if forDisplay { arguments?.append(" ") }
            arguments?.append("--recursive")
        }
        if forDisplay { arguments?.append(" ") }
        arguments?.append(parameter2)
        if forDisplay { arguments?.append(" ") }
        if offsiteServer.isEmpty == false {
            if parameter3.isEmpty == false {
                arguments?.append(parameter3)
                if forDisplay { arguments?.append(" ") }
            }
        }
        if parameter4.isEmpty == false {
            arguments?.append(parameter4)
            if forDisplay { arguments?.append(" ") }
        }
        if offsiteServer.isEmpty == false {
            // We have to check for both global and local ssh parameters.
            // either set global or local, parameter5 = remote server
            // ssh params only apply if remote server
            if parameter5.isEmpty == false {
                if let sshport = config.sshport, sshport != -1,
                   let sshkeypathandidentityfile = config.sshkeypathandidentityfile,
                   sshkeypathandidentityfile.isEmpty == false
                {
                    sshparameterslocal(config: config, forDisplay: forDisplay)
                } else if SharedReference.shared.sshkeypathandidentityfile != nil ||
                    SharedReference.shared.sshport != nil
                {
                    sshparametersglobal(config: config, forDisplay: forDisplay)
                } else {
                    arguments?.append(parameter5)
                    if forDisplay { arguments?.append(" ") }
                    arguments?.append(parameter6)
                    if forDisplay { arguments?.append(" ") }
                }
            }
        }
    }

    // Compute user selected parameters parameter8 ... parameter14
    // Brute force, check every parameter, not special elegant, but it works
    func setParameters8To14(config: SynchronizeConfiguration, dryRun: Bool, forDisplay: Bool) {
        stats = false
        if config.parameter8 != nil {
            appendParameter(parameter: config.parameter8!, forDisplay: forDisplay)
        }
        if config.parameter9 != nil {
            appendParameter(parameter: config.parameter9!, forDisplay: forDisplay)
        }
        if config.parameter10 != nil {
            appendParameter(parameter: config.parameter10!, forDisplay: forDisplay)
        }
        if config.parameter11 != nil {
            appendParameter(parameter: config.parameter11!, forDisplay: forDisplay)
        }
        if config.parameter12 != nil {
            appendParameter(parameter: config.parameter12!, forDisplay: forDisplay)
        }
        if config.parameter13 != nil {
            let split = config.parameter13!.components(separatedBy: "+$")
            if split.count == 2 {
                if split[1] == "date" {
                    appendParameter(parameter: split[0].setdatesuffixbackupstring, forDisplay: forDisplay)
                }
            } else {
                appendParameter(parameter: config.parameter13!, forDisplay: forDisplay)
            }
        }
        if config.parameter14 != nil {
            appendParameter(parameter: config.parameter14!, forDisplay: forDisplay)
        }
        // Append --stats parameter to collect info about run
        if dryRun {
            dryrunparameter(forDisplay: forDisplay)
        } else {
            if stats == false {
                appendParameter(parameter: "--stats", forDisplay: forDisplay)
            }
        }
    }

    // Local params rules global settings
    func sshparameterslocal(config: SynchronizeConfiguration, forDisplay: Bool) {
        // -e "ssh -i ~/.ssh/id_myserver -p 22"
        // -e "ssh -i ~/sshkeypath/sshidentityfile -p portnumber"
        // default is
        // -e "ssh -i ~/.ssh/id_rsa -p 22"
        let parameter5: String = config.parameter5
        let parameter6: String = config.parameter6
        var sshportadded = false
        var sshkeypathandidentityfileadded = false
        // var sshkeypathandidentityfile: String? = config.sshkeypathandidentityfile
        // -e
        arguments?.append(parameter5)
        if forDisplay { arguments?.append(" ") }
        if let sshkeypathandidentityfile = config.sshkeypathandidentityfile {
            sshkeypathandidentityfileadded = true
            if forDisplay { arguments?.append(" \"") }
            // Then check if ssh port is set also
            if let sshport = config.sshport {
                sshportadded = true
                // "ssh -i ~/sshkeypath/sshidentityfile -p portnumber"
                arguments?.append("ssh -i " + sshkeypathandidentityfile + " " + "-p " + String(sshport))
            } else {
                arguments?.append("ssh -i " + sshkeypathandidentityfile)
            }
            if forDisplay { arguments?.append("\" ") }
        }
        if let sshport = config.sshport {
            // "ssh -p xxx"
            if sshportadded == false {
                sshportadded = true
                if forDisplay { arguments?.append(" \"") }
                arguments?.append("ssh -p " + String(sshport))
                if forDisplay { arguments?.append("\" ") }
            }
        } else {
            // ssh
            if sshportadded == false, sshkeypathandidentityfileadded == false {
                arguments?.append(parameter6)
            }
        }
        if forDisplay { arguments?.append(" ") }
    }

    // Global ssh parameters
    func sshparametersglobal(config: SynchronizeConfiguration, forDisplay: Bool) {
        // -e "ssh -i ~/.ssh/id_myserver -p 22"
        // -e "ssh -i ~/sshkeypath/sshidentityfile -p portnumber"
        // default is
        // -e "ssh -i ~/.ssh/id_rsa -p 22"
        let parameter5: String = config.parameter5
        let parameter6: String = config.parameter6
        var sshportadded = false
        var sshkeypathandidentityfileadded = false
        // var sshkeypathandidentityfile: String? = config.sshkeypathandidentityfile
        // -e
        arguments?.append(parameter5)
        if forDisplay { arguments?.append(" ") }
        if let sshkeypathandidentityfile = SharedReference.shared.sshkeypathandidentityfile {
            sshkeypathandidentityfileadded = true
            if forDisplay { arguments?.append(" \"") }
            // Then check if ssh port is set also
            if let sshport = SharedReference.shared.sshport {
                sshportadded = true
                // "ssh -i ~/sshkeypath/sshidentityfile -p portnumber"
                arguments?.append("ssh -i " + sshkeypathandidentityfile + " " + "-p " + String(sshport))
            } else {
                arguments?.append("ssh -i " + sshkeypathandidentityfile)
            }
            if forDisplay { arguments?.append("\" ") }
        }
        if let sshport = SharedReference.shared.sshport {
            // "ssh -p xxx"
            if sshportadded == false {
                sshportadded = true
                if forDisplay { arguments?.append(" \"") }
                arguments?.append("ssh -p " + String(sshport))
                if forDisplay { arguments?.append("\" ") }
            }
        } else {
            // ssh
            if sshportadded == false, sshkeypathandidentityfileadded == false {
                arguments?.append(parameter6)
            }
        }
        if forDisplay { arguments?.append(" ") }
    }

    func dryrunparameter(forDisplay: Bool) {
        let dryrun = "--dry-run"
        arguments?.append(dryrun)
        if forDisplay { arguments?.append(" ") }
        if stats! == false {
            arguments?.append("--stats")
            if forDisplay { arguments?.append(" ") }
        }
    }

    func appendParameter(parameter: String, forDisplay: Bool) {
        if parameter.count > 1 {
            if parameter == "--stats" {
                stats = true
            }
            arguments?.append(parameter)
            if forDisplay {
                arguments?.append(" ")
            }
        }
    }

    func remoteargs(config: SynchronizeConfiguration) {
        offsiteCatalog = config.offsiteCatalog
        offsiteUsername = config.offsiteUsername
        offsiteServer = config.offsiteServer
        if (offsiteServer ?? "").isEmpty == false {
            if let offsiteUsername,
               let offsiteServer,
               // NB: offsiteCatalog
               let offsiteCatalog
            {
                if config.rsyncdaemon != nil {
                    if config.rsyncdaemon == 1 {
                        remoteargs = offsiteUsername + "@" + offsiteServer + "::" + offsiteCatalog
                    } else {
                        remoteargs = offsiteUsername + "@" + offsiteServer + ":" + offsiteCatalog
                    }
                } else {
                    remoteargs = offsiteUsername + "@" + offsiteServer + ":" + offsiteCatalog
                }
            }
        }
    }

    func remoteargssyncremote(config: SynchronizeConfiguration) {
        offsiteCatalog = config.offsiteCatalog
        localCatalog = config.localCatalog
        offsiteUsername = config.offsiteUsername
        offsiteServer = config.offsiteServer
        if (offsiteServer ?? "").isEmpty == false {
            if let offsiteUsername,
               let offsiteServer,
               // NB: locaCatalog
               let localCatalog
            {
                if config.rsyncdaemon != nil {
                    if config.rsyncdaemon == 1 {
                        remoteargs = offsiteUsername + "@" + offsiteServer + "::" + localCatalog
                    } else {
                        remoteargs = offsiteUsername + "@" + offsiteServer + ":" + localCatalog
                    }
                } else {
                    remoteargs = offsiteUsername + "@" + offsiteServer + ":" + localCatalog
                }
            }
        }
    }

    func remoteargssnapshot(config: SynchronizeConfiguration) {
        let snapshotnum = config.snapshotnum ?? 1
        offsiteCatalog = config.offsiteCatalog + String(snapshotnum - 1) + "/"
        offsiteUsername = config.offsiteUsername
        offsiteServer = config.offsiteServer
        if (offsiteServer ?? "").isEmpty == false {
            if let offsiteUsername,
               let offsiteServer,
               // NB: offsiteCatalog
               let offsiteCatalog
            {
                if config.rsyncdaemon != nil {
                    if config.rsyncdaemon == 1 {
                        remoteargs = offsiteUsername + "@" + offsiteServer + "::" + offsiteCatalog
                    } else {
                        remoteargs = offsiteUsername + "@" + offsiteServer + ":" + offsiteCatalog
                    }
                } else {
                    remoteargs = offsiteUsername + "@" + offsiteServer + ":" + offsiteCatalog
                }
            }
        }
    }

    // Additional parameters if snapshot
    func linkdestparameter(config: SynchronizeConfiguration, verify: Bool) {
        let snapshotnum = config.snapshotnum ?? 1
        linkdestparam = "--link-dest=" + config.offsiteCatalog + String(snapshotnum - 1)
        if remoteargs != nil {
            if verify {
                remoteargs! += String(snapshotnum - 1)
            } else {
                remoteargs! += String(snapshotnum)
            }
        }
        if verify {
            offsiteCatalog! += String(snapshotnum - 1)
        } else {
            offsiteCatalog! += String(snapshotnum)
        }
    }

    func argumentsforsynchronize(forDisplay: Bool) {
        arguments?.append(localCatalog ?? "")
        guard offsiteCatalog != nil else { return }
        if (offsiteServer ?? "").isEmpty {
            if forDisplay { arguments?.append(" ") }
            arguments?.append(offsiteCatalog!)
            if forDisplay { arguments?.append(" ") }
        } else {
            if forDisplay { arguments?.append(" ") }
            arguments?.append(remoteargs ?? "")
            if forDisplay { arguments?.append(" ") }
        }
    }

    func argumentsforsynchronizeremote(forDisplay: Bool) {
        guard offsiteCatalog != nil else { return }
        if forDisplay { arguments?.append(" ") }
        arguments?.append(remoteargs ?? "")
        if forDisplay { arguments?.append(" ") }
        arguments?.append(offsiteCatalog ?? "")
        if forDisplay { arguments?.append(" ") }
    }

    func argumentsforsynchronizesnapshot(forDisplay: Bool) {
        guard linkdestparam != nil else {
            arguments?.append(localCatalog ?? "")
            return
        }
        arguments?.append(linkdestparam ?? "")
        if forDisplay { arguments?.append(" ") }
        arguments?.append(localCatalog ?? "")
        if (offsiteServer ?? "").isEmpty {
            if forDisplay { arguments?.append(" ") }
            arguments?.append(offsiteCatalog ?? "")
            if forDisplay { arguments?.append(" ") }
        } else {
            if forDisplay { arguments?.append(" ") }
            arguments?.append(remoteargs ?? "")
            if forDisplay { arguments?.append(" ") }
        }
    }

    func argumentsforrestore(forDisplay: Bool, tmprestore: Bool) {
        if (offsiteServer ?? "").isEmpty {
            arguments?.append(offsiteCatalog ?? "")
            if forDisplay { arguments?.append(" ") }
        } else {
            if forDisplay { arguments?.append(" ") }
            arguments?.append(remoteargs ?? "")
            if forDisplay { arguments?.append(" ") }
        }
        if tmprestore {
            let restorepath = SharedReference.shared.pathforrestore ?? ""
            arguments?.append(restorepath)
        } else {
            arguments?.append(localCatalog ?? "")
        }
    }

    init() {
        arguments = [String]()
    }
}

// swiftlint:enable cyclomatic_complexity type_body_length opening_brace
