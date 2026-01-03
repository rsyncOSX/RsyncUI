//
//  ActorLogToFile.swift
//  RsyncUI
//

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

enum LogfileToReset {
    case rsyncUIlogfile
}

actor ActorLogToFile {
    private let homepath: Homepath?
    private let fileManager = FileManager.default
    private let logName = SharedConstants().logname
    private let maxLogfileSize = SharedConstants().logfilesize

    // MARK: - Helper Properties

    private var logfileURL: URL? {
        guard let fullpathmacserial = homepath?.fullpathmacserial else { return nil }
        return URL(fileURLWithPath: fullpathmacserial).appendingPathComponent(logName)
    }

    private var logfilePath: String? {
        guard let fullpathmacserial = homepath?.fullpathmacserial else { return nil }
        return fullpathmacserial.appending("/") + logName
    }

    // MARK: - Public Methods

    func writeloggfile(_ newlogadata: String, _ reset: Bool) async {
        guard let logURL = logfileURL else { return }

        Logger.process.debugThreadOnly("ActorLogToFile: writeloggfile()")

        do {
            let logfiledata = try await prepareLogData(newlogadata, reset: reset)
            try logfiledata.write(to: logURL)
            Logger.process.debugMessageOnly("ActorLogToFile: writeloggfile() logfile \(logURL.path)")

            try await checkFileSizeAfterWrite()
        } catch {
            await homepath?.propagateError(error: error)
        }
    }

    func readloggfile() async -> [String]? {
        guard let content = await readLogfileContent() else { return nil }
        return content.components(separatedBy: .newlines)
    }

    // MARK: - Private Methods

    private func readLogfileContent() async -> String? {
        guard let logURL = logfileURL,
              let logPath = logfilePath,
              fileManager.locationExists(at: logPath, kind: .file) else {
            return nil
        }

        Logger.process.debugThreadOnly("ActorLogToFile: readLogfileContent()")

        do {
            try await checkAndResetIfTooBig()
            let data = try Data(contentsOf: logURL)
            Logger.process.debugMessageOnly("ActorLogToFile: read logfile \(logURL.path)")
            return String(data: data, encoding: .utf8)
        } catch {
            await homepath?.propagateError(error: error)
            return nil
        }
    }

    private func checkAndResetIfTooBig() async throws {
        let checker = FileSize()
        if let size = try await checker.filesize(),
           Int(truncating: size) > maxLogfileSize {
            let date = Date().localized_string_from_date()
            let resetMessage = date + ": logfile is reset by RsyncUI by checking filesize when reading logfile...\n"
            await writeloggfile(resetMessage, true)
            throw FilesizeError.toobigandresetting
        }
    }

    private func checkFileSizeAfterWrite() async throws {
        let checker = FileSize()
        if let size = try await checker.filesize(),
           Int(truncating: size) > maxLogfileSize {
            throw FilesizeError.toobig
        }
    }

    private func prepareLogData(_ newlogadata: String, reset: Bool) async throws -> Data {
        guard let newdata = newlogadata.data(using: .utf8) else {
            throw NSError(domain: "ActorLogToFile", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode log data"])
        }

        guard let logURL = logfileURL,
              let logPath = logfilePath else {
            throw NSError(domain: "ActorLogToFile", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid log file path"])
        }

        Logger.process.debugThreadOnly("ActorLogToFile: prepareLogData()")

        if reset {
            return newdata
        }

        if fileManager.locationExists(at: logPath, kind: .file) {
            Logger.process.debugMessageOnly("ActorLogToFile: append existing logfile \(logURL.path)")
            var existingData = try Data(contentsOf: logURL)
            existingData.append(newdata)
            return existingData
        } else {
            Logger.process.debugMessageOnly("ActorLogToFile: create new logfile \(logURL.path)")
            return newdata
        }
    }

    private func appendlogg(command: String, stringoutputfromrsync: [String]) async {
        let date = Date().localized_string_from_date()
        let header = "\n\(date): \(command)\n"
        let output = stringoutputfromrsync.joined(separator: "\n")
        let logfile = await (readLogfileContent() ?? "") + header + output + "\n"
        await writeloggfile(logfile, true)
    }

    // MARK: - Initializers

    @discardableResult
    init() async {
        homepath = await Homepath()
    }

    @discardableResult
    init(_: LogfileToReset) async {
        let date = Date().localized_string_from_date()
        let reset = "\(date): logfile is reset...\n"
        homepath = await Homepath()
        await writeloggfile(reset, true)
    }

    @discardableResult
    init(_ command: String, _ stringoutputfromrsync: [String]?) async {
        homepath = await Homepath()
        if let stringoutputfromrsync {
            await appendlogg(command: command, stringoutputfromrsync: stringoutputfromrsync)
        }
    }
}

