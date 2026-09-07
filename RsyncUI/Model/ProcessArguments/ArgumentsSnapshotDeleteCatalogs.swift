import Foundation
import RsyncArguments

/// Only a numbered snapshot belonging to this configured root may be removed.
enum SnapshotDeletionPath {
    static func target(root: String, catalog: String) throws -> String {
        guard !root.isEmpty,
              root.split(separator: "/").contains(where: { $0 != "." }),
              !["/", ".", ".."].contains(root),
              !root.split(separator: "/").contains(".."),
              !root.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }),
              catalog.hasPrefix("./") else { throw SnapshotDeletionError.invalidPath }
        let number = String(catalog.dropFirst(2))
        guard !number.isEmpty, number.allSatisfy({ $0.isASCII && $0.isNumber }),
              let value = Int(number), value > 0 else { throw SnapshotDeletionError.invalidPath }
        // Match the snapshot path convention used by RsyncArguments when creating snapshots.
        return root + number
    }

    static func shellQuote(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\"'\"'") + "'"
    }
}

enum SnapshotDeletionError: LocalizedError {
    case invalidPath

    var errorDescription: String? {
        "Cannot delete this snapshot: its folder or configured backup root is invalid."
    }
}

@MainActor
final class ArgumentsSnapshotDeleteCatalogs {
    private let arguments: [String]
    private let command: String

    func getArguments() -> [String]? {
        arguments
    }

    func getCommand() -> String? {
        command
    }

    init(config: SynchronizeConfiguration, remotecatalog: String) throws {
        guard config.task == SharedReference.shared.snapshot,
              remotecatalog.hasPrefix(config.offsiteCatalog) else { throw SnapshotDeletionError.invalidPath }
        let catalog = "./" + remotecatalog.dropFirst(config.offsiteCatalog.count)
        let target = try SnapshotDeletionPath.target(root: config.offsiteCatalog, catalog: catalog)
        if config.offsiteServer.isEmpty {
            command = "/bin/rm"
            arguments = ["-rf", "--", target]
        } else {
            let builder = SnapshotDelete(sshParameters: SSHParams().sshparams(config: config))
            command = builder.remoteCommand
            // Preserve the package's SSH options, replacing its unquoted remote command.
            arguments = Array(builder.snapshotDelete(remoteCatalog: target).dropLast()) +
                ["rm -rf -- \(SnapshotDeletionPath.shellQuote(target))"]
        }
    }
}
