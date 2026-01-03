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

actor ActorLogToFile {
    private let homepath: Homepath?
    private let fileManager = FileManager.default
    private let logName = SharedConstants().logname
    private let maxLogfileSize = SharedConstants().logfilesize
    private lazy var fileSizeChecker = FileSize()

    // MARK: - Helper Properties

    private var logfileURL: URL? {
        guard let fullpathmacserial = homepath?.fullpathmacserial else { return nil }
        return URL(fileURLWithPath: fullpathmacserial).appendingPathComponent(logName)
    }

    // MARK: - Public Methods

    func writeloggfile(_ newlogadata: String, _ reset: Bool) async {
        guard let logURL = logfileURL else { return }

        Logger.process.debugThreadOnly("ActorLogToFile: writeloggfile()")

        do {
            guard let newdata = newlogadata.data(using: .utf8) else {
                throw NSError(domain: "ActorLogToFile", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode log data"])
            }

            if reset {
                try newdata.write(to: logURL)
            } else {
                let logPath = logURL.path
                if fileManager.locationExists(at: logPath, kind: .file) {
                    Logger.process.debugMessageOnly("ActorLogToFile: append existing logfile \(logURL.path)")
                    try appendDataToFile(logURL, newdata)
                } else {
                    Logger.process.debugMessageOnly("ActorLogToFile: create new logfile \(logURL.path)")
                    try newdata.write(to: logURL)
                }
            }

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
              fileManager.fileExists(atPath: logURL.path) else {
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
        if let size = try await fileSizeChecker.filesize(),
           Int(truncating: size) > maxLogfileSize {
            let date = Date().localized_string_from_date()
            let resetMessage = date + ": logfile is reset by RsyncUI by checking filesize when reading logfile...\n"
            await writeloggfile(resetMessage, true)
            throw FilesizeError.toobigandresetting
        }
    }

    private func checkFileSizeAfterWrite() async throws {
        if let size = try await fileSizeChecker.filesize(),
           Int(truncating: size) > maxLogfileSize {
            throw FilesizeError.toobig
        }
    }

    private func appendDataToFile(_ url: URL, _ data: Data) throws {
        let fileHandle = try FileHandle(forWritingTo: url)
        defer {
            do { try fileHandle.close() } catch { /* ignore close errors */ }
        }
        try fileHandle.seekToEnd()
        try fileHandle.write(contentsOf: data)
    }

    // MARK: - Initializers

    init() async {
        homepath = await Homepath()
    }

    // MARK: - Reset and Logging Methods

    func reset() async {
        let date = Date().localized_string_from_date()
        let resetMessage = "\(date): logfile is reset...\n"
        await writeloggfile(resetMessage, true)
    }

    func logOutput(_ command: String, _ stringoutputfromrsync: [String]?) async {
        guard let stringoutputfromrsync, !stringoutputfromrsync.isEmpty else { return }

        let date = Date().localized_string_from_date()
        let header = "\n\(date): \(command)\n"
        let output = stringoutputfromrsync.joined(separator: "\n")
        let logEntry = header + output + "\n"
        await writeloggfile(logEntry, false)
    }
}
