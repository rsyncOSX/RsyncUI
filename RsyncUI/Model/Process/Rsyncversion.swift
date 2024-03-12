//
//  Rsyncversion.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/01/2021.
//

import Foundation
import Observation

@Observable
final class Rsyncversion {
    func getrsyncversion() {
        if SharedReference.shared.norsync == false {
            let command = RsyncProcessNOFilehandler(arguments: ["--version"],
                                                    processtermination: processtermination)

            command.executeProcess()
        }
    }

    init() {
        let silicon = ProcessInfo().machineHardwareName?.contains("arm64") ?? false
        if silicon {
            SharedReference.shared.macosarm = true
        } else {
            SharedReference.shared.macosarm = false
        }
    }
}

extension Rsyncversion {
    func processtermination(data: [String]?) {
        guard data?.count ?? 0 > 0 else { return }
        if let rsyncversionshort = data?[0],
           let rsyncversionstring = data?.joined(separator: "\n")
        {
            SharedReference.shared.rsyncversionshort = rsyncversionshort
            SharedReference.shared.rsyncversionstring = rsyncversionstring
        }
    }
}

extension ProcessInfo {
    /// Returns a `String` representing the machine hardware name or nil if there was an error invoking `uname(_:)`
    ///  or decoding the response. Return value is the equivalent to running `$ uname -m` in shell.
    var machineHardwareName: String? {
        var sysinfo = utsname()
        let result = uname(&sysinfo)
        guard result == EXIT_SUCCESS else { return nil }
        let data = Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN))
        guard let identifier = String(bytes: data, encoding: .ascii) else { return nil }
        return identifier.trimmingCharacters(in: .controlCharacters)
    }
}
