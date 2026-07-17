//
//  RuntimeRsyncArguments.swift
//  RsyncUI
//

enum RuntimeRsyncArguments {
    static func addingItemizedChanges(
        to arguments: [String],
        forDisplay: Bool
    ) -> [String] {
        let meaningfulIndices = arguments.indices.filter { arguments[$0] != " " }
        guard meaningfulIndices.count >= 2 else {
            return arguments
        }

        let sourceIndex = meaningfulIndices[meaningfulIndices.count - 2]
        let optionTerminatorIndex = meaningfulIndices
            .prefix(meaningfulIndices.count - 2)
            .first { arguments[$0] == "--" }
        let insertionIndex = optionTerminatorIndex ?? sourceIndex

        guard arguments[..<insertionIndex].contains("--itemize-changes") == false else {
            return arguments
        }

        var updatedArguments = arguments
        updatedArguments.insert("--itemize-changes", at: insertionIndex)
        if forDisplay {
            updatedArguments.insert(" ", at: insertionIndex + 1)
        }
        return updatedArguments
    }
}
