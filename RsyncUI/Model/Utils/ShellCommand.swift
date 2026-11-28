//
//  ShellCommand.swift
//  RsyncUI
//

import Foundation

/// Formats a command and its arguments as one line which can be pasted into a shell.
enum ShellCommand {
    static func line(_ command: String, _ arguments: [String]) -> String {
        ([command] + arguments).map(quoted).joined(separator: " ")
    }

    /// Single quote an argument if the shell would split or expand it.
    static func quoted(_ argument: String) -> String {
        let needsQuotes = argument.isEmpty || argument.hasPrefix("~") ||
            argument.unicodeScalars.contains { !safeCharacters.contains($0) }
        guard needsQuotes else { return argument }
        return "'" + argument.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private static let safeCharacters = CharacterSet.alphanumerics
        .union(CharacterSet(charactersIn: "-_./:=@%+,~"))
}
