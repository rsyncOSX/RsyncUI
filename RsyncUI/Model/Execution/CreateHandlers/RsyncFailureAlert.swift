import Foundation

/// A bounded stderr summary for presentation, independent of package error storage.
struct RsyncFailureAlert: LocalizedError {
    let exitCode: Int32
    let lines: [String]

    init(exitCode: Int32, chunks: [String]) {
        self.exitCode = exitCode
        var tail: [String] = []
        var latestError: String?
        // Package entries are stderr chunks, each of which can contain many lines.
        for chunk in chunks {
            chunk.enumerateLines { line, _ in
                if line.localizedCaseInsensitiveContains("error") {
                    latestError = line
                }
                tail.append(line)
                if tail.count > 10 {
                    tail.removeFirst()
                }
            }
        }
        if let latestError,
           !tail.contains(where: { $0.localizedCaseInsensitiveContains("error") }) {
            tail = [latestError] + tail.suffix(9)
        }
        lines = tail
    }

    var errorDescription: String? {
        (["rsync exited with code \(exitCode)."] + lines).joined(separator: "\n")
    }
}
