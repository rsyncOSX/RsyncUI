//
//  ActorLogToFile.swift
//  rcloneosx
//
//  Created by Thomas Evensen on 20.11.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable non_optional_string_data_conversion

import Foundation
import OSLog

enum FilesizeError: LocalizedError {
    case toobig
    case toobigandresetting

    var errorDescription: String? {
        switch self {
        case .toobig:
            "Logfile is too big\nPlease reset logfile"
        case .toobigandresetting:
            "Logfile is too big\nResetting logfile"
        }
    }
}

actor ActorLogToFile {
    @concurrent
    nonisolated func writeloggfile(_ newlogadata: String, _ reset: Bool) async {
        let path = await Homepath()
        if let fullpathmacserial = path.fullpathmacserial {
            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let logfileURL = fullpathmacserialURL.appendingPathComponent(SharedConstants().logname)
            if Thread.checkIsMainThread() {
                Logger.process.info("LogToFile: writeloggfile() Running on main thread")
            } else {
                Logger.process.info("LogToFile: writeloggfile() NOT on main thread, currently on \(Thread.current, privacy: .public)")
            }
            if let logfiledata = await appendloggfileData(newlogadata, reset) {
                do {
                    try logfiledata.write(to: logfileURL)
                    Logger.process.info("LogToFile: writeloggfile() logfile \(logfileURL.path, privacy: .public)")
                    let checker = FileSize()
                    // Task {
                    do {
                        if let size = try await checker.filesize() {
                            if Int(truncating: size) > SharedConstants().logfilesize {
                                throw FilesizeError.toobig
                            }
                        }
                    } catch let e {
                        let error = e
                        await path.propogateerror(error: error)
                    }
                    // }
                } catch let e {
                    let error = e
                    await path.propogateerror(error: error)
                }
            }
        }
    }

    @concurrent
    nonisolated func readloggfile() async -> [String]? {
        let path = await Homepath()
        let fm = FileManager.default
        if let fullpathmacserial = path.fullpathmacserial {
            let logfileString = fullpathmacserial.appending("/") + SharedConstants().logname
            guard fm.locationExists(at: logfileString, kind: .file) == true else { return nil }

            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let logfileURL = fullpathmacserialURL.appendingPathComponent(SharedConstants().logname)
            
            if Thread.checkIsMainThread() {
                Logger.process.info("LogToFile: readloggfile() Running on main thread")
            } else {
                Logger.process.info("LogToFile: readloggfile() NOT on main thread, currently on \(Thread.current, privacy: .public)")
            }
            do {
                let checker = FileSize()
                if let size = try await checker.filesize() {
                    if Int(truncating: size) > SharedConstants().logfilesize {
                        throw FilesizeError.toobigandresetting
                    }
                }

            } catch let e {
                let error = e
                await path.propogateerror(error: error)
                // Reset loggfile
                let date = Date().localized_string_from_date()
                let reset = date + ": " + "logfile is reset by RsyncUI by checking filesize when reading logfile..." + "\n"
                await writeloggfile(reset, true)
            }

            do {
                let data = try Data(contentsOf: logfileURL)
                Logger.process.info("LogToFile: read logfile \(logfileURL.path, privacy: .public)")
                let logfile = String(data: data, encoding: .utf8)
                return logfile.map { line in
                    line.components(separatedBy: .newlines)
                }
            } catch let e {
                let error = e
                await path.propogateerror(error: error)
            }
        }

        return nil
    }

    @concurrent
    private nonisolated func readloggfileasline() async -> String? {
        let path = await Homepath()
        let fm = FileManager.default
        if let fullpathmacserial = path.fullpathmacserial {
            let logfileString = fullpathmacserial.appending("/") + SharedConstants().logname
            guard fm.locationExists(at: logfileString, kind: .file) == true else { return nil }

            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let logfileURL = fullpathmacserialURL.appendingPathComponent(SharedConstants().logname)
            if Thread.checkIsMainThread() {
                Logger.process.info("LogToFile: readloggfileasline() Running on main thread")
            } else {
                Logger.process.info("LogToFile: readloggfileasline() NOT on main thread, currently on \(Thread.current, privacy: .public)")
            }
            do {
                let checker = FileSize()
                if let size = try await checker.filesize() {
                    if Int(truncating: size) > SharedConstants().logfilesize {
                        throw FilesizeError.toobigandresetting
                    }
                }

            } catch let e {
                let error = e
                await path.propogateerror(error: error)
                // Reset loggfile
                let date = Date().localized_string_from_date()
                let reset = date + ": " + "logfile is reset by RsyncUI by checking filesize when reading logfile..." + "\n"
                await writeloggfile(reset, true)
            }

            do {
                let data = try Data(contentsOf: logfileURL)
                Logger.process.info("LogToFile: read logfile \(logfileURL.path, privacy: .public)")
                return String(data: data, encoding: .utf8)

            } catch let e {
                let error = e
                await path.propogateerror(error: error)
            }
        }

        return nil
    }

    @concurrent
    private nonisolated func appendloggfileData(_ newlogadata: String, _ reset: Bool) async -> Data? {
        let path = await Homepath()
        let fm = FileManager.default
        if let fullpathmacserial = path.fullpathmacserial {
            let logfileString = fullpathmacserial.appending("/") + SharedConstants().logname
            // guard fm.locationExists(at: logfileString, kind: .file) == true else { return nil }

            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let logfileURL = fullpathmacserialURL.appendingPathComponent(SharedConstants().logname)
            if Thread.checkIsMainThread() {
                Logger.process.info("LogToFile: appendloggfileData() Running on main thread")
            } else {
                Logger.process.info("LogToFile: appendloggfileData() NOT on main thread, currently on \(Thread.current, privacy: .public)")
            }
            
            if let newdata = newlogadata.data(using: .utf8) {
                do {
                    if reset {
                        // Only return reset string
                        return newdata
                    } else {
                        // Or append any new log data
                        if fm.locationExists(at: logfileString, kind: .file) == true {
                            Logger.process.info("LogToFile: append existing logfile \(logfileURL.path, privacy: .public)")
                            let data = try Data(contentsOf: logfileURL)
                            var returneddata = data
                            returneddata.append(newdata)
                            return returneddata
                        } else {
                            // Or if first time write logfile ony return new log data
                            Logger.process.info("LogToFile: create new logfile \(logfileURL.path, privacy: .public)")
                            return newdata
                        }
                    }
                } catch let e {
                    let error = e
                    await path.propogateerror(error: error)
                }
            }
        }

        return nil
    }

    private func appendlogg(command: String, stringoutputfromrsync: [String]) async {
        let date = Date().localized_string_from_date()
        // Build header line
        let header = "\n" + date + ": " + command + "\n"
        // Join rsync output into a single string with newlines
        let output = stringoutputfromrsync.joined(separator: "\n")

        // Read existing logfile as a single string
        var logfile = await readloggfileasline() ?? ""
        // Append header and output, always ending with a newline
        logfile += header + output + "\n"
        // Write a new logfile with appended new lines
        await writeloggfile(logfile, true)
    }

    @discardableResult
    init(_ reset: Bool) async {
        if reset {
            // Reset loggfile
            let date = Date().localized_string_from_date()
            let reset = date + ": " + "logfile is reset..." + "\n"
            await writeloggfile(reset, true)
        }
    }

    @discardableResult
    init(_ command: String, _ stringoutputfromrsync: [String]?) async {
        if let stringoutputfromrsync {
            await appendlogg(command: command, stringoutputfromrsync: stringoutputfromrsync)
        }
    }
}

// swiftlint:enable non_optional_string_data_conversion
