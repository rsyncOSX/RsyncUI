//
//  ItemizedOutput.swift
//  RsyncUI
//

import Foundation
import SwiftUI

enum ItemizedChangeKind: String {
    case added = "Added"
    case updated = "Updated"
    case deleted = "Deleted"
    case metadata = "Metadata"
    case other = "Other"

    var systemImage: String {
        switch self {
        case .added: "plus.circle.fill"
        case .updated: "arrow.triangle.2.circlepath.circle.fill"
        case .deleted: "minus.circle.fill"
        case .metadata: "info.circle.fill"
        case .other: "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .added: .green
        case .updated: .blue
        case .deleted: .red
        case .metadata: .orange
        case .other: .secondary
        }
    }
}

struct ItemizedOutputRecord {
    let kind: ItemizedChangeKind
    let path: String
    let code: String

    init?(_ record: String, rsyncVersion3: Bool = false) {
        let trimmed = record.trimmingCharacters(in: .newlines)
        guard trimmed.isEmpty == false else { return nil }

        if trimmed.hasPrefix("*deleting") {
            let deletionPrefix = rsyncVersion3 ? "*deleting   " : "*deleting "
            guard trimmed.hasPrefix(deletionPrefix) else { return nil }

            kind = .deleted
            path = String(trimmed.dropFirst(deletionPrefix.count))
            guard path.isEmpty == false else { return nil }
            code = "*deleting"
            return
        }

        let prefixLength = Self.prefixLength(in: trimmed)
        guard let prefixLength else { return nil }

        code = String(trimmed.prefix(prefixLength))
        path = String(trimmed.dropFirst(prefixLength + 1))
        guard path.isEmpty == false else { return nil }

        let attributes = code.dropFirst(2)
        kind = if attributes.isEmpty == false, attributes.allSatisfy({ $0 == "+" }) {
            .added
        } else if code.first == "." {
            .metadata
        } else if code.first == ">" || code.first == "<" || code.first == "c" {
            .updated
        } else {
            .other
        }
    }

    private static func prefixLength(in record: String) -> Int? {
        let characters = Array(record)
        if characters.count >= 13, characters[12] == " " {
            return 12
        }
        if characters.count >= 12, characters[11] == " " {
            return 11
        }
        if characters.count >= 10, characters[9] == " " {
            return 9
        }
        return nil
    }
}

struct ItemizedOutputRow: View {
    let record: String
    let rsyncVersion3: Bool

    var body: some View {
        if let parsed = ItemizedOutputRecord(record, rsyncVersion3: rsyncVersion3) {
            HStack(spacing: 10) {
                Label(parsed.kind.rawValue, systemImage: parsed.kind.systemImage)
                    .foregroundStyle(parsed.kind.color)
                    .font(.caption.weight(.semibold))
                    .frame(width: 92, alignment: .leading)

                Text(parsed.path)
                    .font(.caption.monospaced())
                    .lineLimit(1)
                    .textSelection(.enabled)

                Spacer()

                Text(parsed.code)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        } else {
            Text(record)
                .font(.caption.monospaced())
                .textSelection(.enabled)
        }
    }
}
