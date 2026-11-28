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
    static let shared = ActorLogToFile()

    private var homepath: Homepath?
    private let fileManager = FileManager.default
    private let logName = SharedConstants().logname
    private let maxLogfileSize = SharedConstants().logfilesize
    private lazy var fileSizeChecker = FileSize()
    private var warnedAboutSize = false

    // MARK: - Helper Properties

    private func getHomepath() async -> Homepath? {
        if homepath == nil {
            homepath = await Homepath()
        }
        return homepath
    }

    private func getLogfileURL() async -> URL? {
        guard let fullpathmacserial = await (getHomepath())?.fullpathmacserial else { return nil }
        return URL(fileURLWithPath: fullpathmacserial).appendingPathComponent(logName)
    }

    // MARK: - Public Methods

    @discardableResult
    func writeloggfile(_ newlogadata: String, _ reset: Bool) async -> Bool {
        guard let logURL = await getLogfileURL() else { return false }

        Logger.process.debugThreadOnly("ActorLogToFile: writeloggfile()")

        do {
            guard let newdata = newlogadata.data(using: .utf8) else {
                throw NSError(domain: "ActorLogToFile", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode log data"])
            }

            if reset {
                try newdata.write(to: logURL)
                warnedAboutSize = false
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
        } catch {
            await getHomepath()?.propagateError(error: error)
            return false
        }
        // The data is written. A large logfile is a warning, not a failed write.
        if Self.shouldWarnAboutSize(await currentLogfileSize(), limit: maxLogfileSize, alreadyWarned: warnedAboutSize) {
            warnedAboutSize = true
            await getHomepath()?.propagateError(error: FilesizeError.toobig)
        }
        return true
    }

    /// Warn once per session when the logfile grows past the limit, and again after a reset.
    static func shouldWarnAboutSize(_ size: Int?, limit: Int, alreadyWarned: Bool) -> Bool {
        guard let size, size > limit else { return false }
        return !alreadyWarned
    }

    private func currentLogfileSize() async -> Int? {
        guard let size = try? await fileSizeChecker.filesize() else { return nil }
        return Int(truncating: size)
    }

    func readloggfile() async -> [String]? {
        guard let content = await readLogfileContent() else { return nil }
        return content.components(separatedBy: .newlines)
    }

    // MARK: - Private Methods

    private func readLogfileContent() async -> String? {
        guard let logURL = await getLogfileURL(),
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
            await getHomepath()?.propagateError(error: error)
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

    private func appendDataToFile(_ url: URL, _ data: Data) throws {
        let fileHandle = try FileHandle(forWritingTo: url)
        defer {
            do { try fileHandle.close() } catch { /* ignore close errors */ }
        }
        try fileHandle.seekToEnd()
        try fileHandle.write(contentsOf: data)
    }

    // MARK: - Initializers

    private init() {}

    // MARK: - Reset and Logging Methods

    func reset() async {
        let date = Date().localized_string_from_date()
        let resetMessage = "\(date): logfile is reset...\n"
        await writeloggfile(resetMessage, true)
    }

    @discardableResult
    func logOutput(_ command: String, _ stringoutputfromrsync: [String]?) async -> Bool {
        guard let stringoutputfromrsync, !stringoutputfromrsync.isEmpty else { return true }

        let date = Date().localized_string_from_date()
        let header = "\n\(date): \(command)\n"
        let output = stringoutputfromrsync.joined(separator: "\n")
        let logEntry = header + output + "\n"
        return await writeloggfile(logEntry, false)
    }
}
