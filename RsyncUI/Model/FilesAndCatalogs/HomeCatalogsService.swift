//
//  Homecatalogs.swift
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
        let fm = FileManager.default
        let homeURL = fm.homeDirectoryForCurrentUser
        
        do {
            return try fm.contentsOfDirectory(
                at: homeURL,
                includingPropertiesForKeys: [.isDirectoryKey]
            )
            .filter { $0.hasDirectoryPath }
            .map { Catalog($0.lastPathComponent) }
        } catch {
            return []
        }
    }
}
