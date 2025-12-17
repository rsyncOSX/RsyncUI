//
//  Rsyncversion.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/01/2021.
//

import Foundation
import Observation
import OSLog
import RsyncProcessStreaming

@Observable @MainActor
final class Rsyncversion {
    // Streaming strong references
    private var streamingHandlers: RsyncProcessStreaming.ProcessHandlers?
    private var activeStreamingProcess: RsyncProcessStreaming.RsyncProcess?

    func getRsyncVersion() {
        streamingHandlers = CreateStreamingHandlers().createHandlers(
            fileHandler: { _ in },
            processTermination: { output, hiddenID in
                self.processTermination(stringoutputfromrsync: output, hiddenID: hiddenID)
            }
        )
        guard let streamingHandlers else { return }

        do {
            try SetandValidatepathforrsync().validateLocalPathForRsync()
        } catch {
            SharedReference.shared.norsync = true
            SharedReference.shared.rsyncversionshort = "No valid rsync deteced"
        }
        if SharedReference.shared.norsync == false {
            let process = RsyncProcessStreaming.RsyncProcess(
                arguments: ["--version"],
                handlers: streamingHandlers,
                useFileHandler: false
            )
            do {
                try process.executeProcess()
                activeStreamingProcess = process
            } catch let err {
                let error = err
                SharedReference.shared.errorobject?.alert(error: error)
            }
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
    func processTermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        guard stringoutputfromrsync?.count ?? 0 > 0 else { return }
        if let rsyncversionshort = stringoutputfromrsync?[0] {
            let short = rsyncversionshort.replacingOccurrences(of: "protocol", with: "\nprotocol")
            let result = short.replacingOccurrences(of: "(?s)Web site.*", with: "", options: .regularExpression)
            SharedReference.shared.rsyncversionshort = result

            if rsyncversionshort.contains("version 3.") {
                SharedReference.shared.rsyncversion3 = true
                Logger.process.debugMessageOnly("Rsyncversion: version 3.x of rsync discovered")
            } else {
                SharedReference.shared.rsyncversion3 = false
                Logger.process.debugMessageOnly("Rsyncversion: default openrsync discovered")
            }
        }
        // Release streaming references to avoid retain cycles
        activeStreamingProcess = nil
        streamingHandlers = nil
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
