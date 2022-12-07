//
//  RsyncOSXViewGetRsyncversion.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/01/2021.
//

import Foundation

// Getting and setting the rsync version.
final class GetRsyncversion: ObservableObject {
    func getrsyncversion() async {
        if SharedReference.shared.norsync == false {
            _ = await RsyncAsync(arguments: ["--version"],
                                 processtermination: processtermination).executeProcess()
        }
    }

    func macosrm() {
        let silicon = ProcessInfo().machineHardwareName?.contains("arm64") ?? false
        if silicon {
            SharedReference.shared.macosarm = true
        } else {
            SharedReference.shared.macosarm = false
        }
    }
}

extension GetRsyncversion {
    func processtermination(data: [String]?) {
        if let rsyncversionshort = data?[0] {
            SharedReference.shared.rsyncversionshort = rsyncversionshort
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
