//
//  ActorFileSize.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/06/2025.
//

import Foundation
import OSLog

@MainActor
struct FileSize {
    // Only logfile is checked for size, URL-file for logfile is evaluated within function

    func filesize() throws -> NSNumber? {
        let path = Homepath()
        let fm = FileManager.default
        if let fullpathmacserial = path.fullpathmacserial {
            let logfileString = fullpathmacserial.appending("/") + SharedConstants().logname
            guard fm.locationExists(at: logfileString, kind: .file) == true else { return nil }

            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let logfileURL = fullpathmacserialURL.appendingPathComponent(SharedConstants().logname)

            do {
                // Return filesize
                if let filesize = try fm.attributesOfItem(atPath: logfileURL.path)[FileAttributeKey.size] as? NSNumber {
                    Logger.process.info("FileChecker: Filesize of logfile \(filesize, privacy: .public)")
                    return filesize
                }
            } catch {
                return nil
            }
        }
        return nil
    }
}
