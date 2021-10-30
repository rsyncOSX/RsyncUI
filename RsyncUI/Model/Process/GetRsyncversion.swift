//
//  RsyncOSXViewGetRsyncversion.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/01/2021.
//

import Foundation

// Getting and setting the rsync version.
final class GetRsyncversion: ObservableObject, UpdateRsyncVersionString {
    var rsyncversion = ""

    func update() {
        let silicon = ProcessInfo().machineHardwareName?.contains("arm64") ?? false
        if silicon {
            SharedReference.shared.macosarm = true
        } else {
            SharedReference.shared.macosarm = false
        }
        // Must set new values ahead of save to get correct string
        // SharedReference.shared.rsyncversion3 = ver
        _ = RsyncVersionString(object: self)
    }

    func updatersyncversionstring(rsyncversion: String) {
        self.rsyncversion = rsyncversion
    }

    init() {
        _ = RsyncVersionString(object: self)
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
