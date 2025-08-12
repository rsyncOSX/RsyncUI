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

    var errorDescription: String? {
        switch self {
        case .toobig:
            "Logfile is too big\n Please reset file"
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
            Logger.process.info("LogToFile: writeloggfile() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
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
            Logger.process.info("LogToFile: readloggfile() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")

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
            Logger.process.info("LogToFile: readloggfileasline() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")

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
            Logger.process.info("LogToFile: appendloggfileData() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")

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

    private func minimumlogging(command: String, stringoutputfromrsync: [String]) async {
        let date = Date().localized_string_from_date()
        var tmplogg = [String]()

        var startindex = stringoutputfromrsync.count - 20
        if startindex < 0 { startindex = 0 }

        tmplogg.append("\n" + date + ": " + command + "\n")

        var count = 0
        let tmploggrsync = stringoutputfromrsync.compactMap { line in
            count += 1
            return startindex >= count ? nil : line
        }

        var logfile = await readloggfileasline()

        if logfile == nil {
            logfile = tmplogg.joined(separator: "\n") + tmploggrsync.joined(separator: "\n")
        } else {
            logfile! += tmplogg.joined(separator: "\n") + tmploggrsync.joined(separator: "\n")
        }
        if let logfile {
            await writeloggfile(logfile, false)
        }
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
    init(command: String, stringoutputfromrsync: [String]?) async {
        if let stringoutputfromrsync {
            await minimumlogging(command: command, stringoutputfromrsync: stringoutputfromrsync)
        }
    }
}

// swiftlint:enable non_optional_string_data_conversion
