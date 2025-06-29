//
//  ObservableSSH.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/03/2021.
//

import Foundation
import Observation
import SSHCreateKey

@Observable @MainActor
final class ObservableSSH {
    // Global SSH parameters
    // Have to convert String -> Int before saving
    // Set the current value as placeholder text
    var sshportnumber: String = .init(SharedReference.shared.sshport ?? 22)
    // SSH keypath and identityfile, the settings View is picking up the current value
    // Set the current value as placeholder text
    var sshkeypathandidentityfile: String = SharedReference.shared.sshkeypathandidentityfile ?? ""
    var sshcreatekey: SSHCreateKey?

    func sshkeypath(_ keypath: String) -> Bool {
        guard keypath.isEmpty == false else {
            SharedReference.shared.sshkeypathandidentityfile = nil
            return false
        }
        
        let verified = verifysshkeypath(keypath)
        if verified == true {
            SharedReference.shared.sshkeypathandidentityfile = keypath
            return true
        } else {
            return false
        }
    }

    func setsshport(_ port: String) -> Bool {
        guard port.isEmpty == false else {
            SharedReference.shared.sshport = nil
            return false
        }
        
        let verified = verifysshport(port)
        if verified == true {
            SharedReference.shared.sshport = Int(port)
            return true
        } else {
            return false
        }
    }
    
    // Verify SSH keypathidentityfile
    func verifysshkeypath(_ keypath: String) -> Bool {
        guard keypath.isEmpty == false else { return false }
        if keypath.first != "~" { return false }
        let tempsshkeypath = keypath
        let numOccurrences = keypath.filter{ $0 == "/" }.count
        guard numOccurrences == 2 else { return false }
        return true
    }
    
    // Verify SSH port is a valid INT
    func verifysshport(_ port: String) -> Bool {
        guard port.isEmpty == false else { return false }
        if Int(port) != nil {
            return true
        } else {
            return false
        }
    }

    init() {
        sshcreatekey = SSHCreateKey(sharedsshport: String(SharedReference.shared.sshport ?? -1),
                                    sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile)
    }
}
