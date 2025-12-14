//
//  HomeCatalogsService.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 09/08/2025.
//

import Foundation

struct Catalog: Identifiable, Hashable {
    var id: String { name }
    let name: String

    init(_ name: String) {
        self.name = name
    }
}

struct HomeCatalogsService {
    func homeCatalogs() -> [Catalog] {
        let fmanager = FileManager.default
        let homeURL = fmanager.homeDirectoryForCurrentUser

        do {
            return try fmanager.contentsOfDirectory(
                at: homeURL,
                includingPropertiesForKeys: [.isDirectoryKey]
            )
            .filter(\.hasDirectoryPath)
            .map { Catalog($0.lastPathComponent) }
        } catch {
            return []
        }
    }
}
