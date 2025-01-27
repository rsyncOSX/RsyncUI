//
//  Rsyncversion.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/01/2021.
//

import Foundation
import Observation

@Observable @MainActor
final class Rsyncversion {
    func getrsyncversion() {
        do {
            try SetandValidatepathforrsync().validateandrsyncpath()
        } catch {
            SharedReference.shared.norsync = true
            SharedReference.shared.rsyncversionshort = "No valid rsync deteced"
        }
        if SharedReference.shared.norsync == false {
            let command = ProcessRsyncObserving(arguments: ["--version"],
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
    func processtermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        guard stringoutputfromrsync?.count ?? 0 > 0 else { return }
        if let rsyncversionshort = stringoutputfromrsync?[0] {
            SharedReference.shared.rsyncversionshort =
                rsyncversionshort.replacingOccurrences(of: "protocol", with: "\nprotocol")

            if rsyncversionshort.contains("version 3.3") || rsyncversionshort.contains("version 3.4") {
                SharedReference.shared.rsyncversion3 = true
            } else {
                SharedReference.shared.rsyncversion3 = false
            }
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
