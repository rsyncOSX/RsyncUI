//
//  RuntimeRsyncArguments.swift
//  RsyncUI
//

enum RuntimeRsyncArguments {
    static func addingItemizedChanges(
        to arguments: [String],
        forDisplay: Bool
    ) -> [String] {
        guard arguments.contains("--itemize-changes") == false else {
            return arguments
        }

        let meaningfulIndices = arguments.indices.filter { arguments[$0] != " " }
        guard meaningfulIndices.count >= 2 else {
            return arguments
        }

        let sourceIndex = meaningfulIndices[meaningfulIndices.count - 2]
        var updatedArguments = arguments
        updatedArguments.insert("--itemize-changes", at: sourceIndex)
        if forDisplay {
            updatedArguments.insert(" ", at: sourceIndex + 1)
        }
        return updatedArguments
    }
}
