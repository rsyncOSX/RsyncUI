//
//  Homecatalogs.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 09/08/2025.
//

import Foundation

struct Catalognames: Identifiable, Hashable {
    let id = UUID()
    var catalogname: String

    init(_ name: String) {
        catalogname = name
    }
}

@MainActor
struct Homecatalogs {
    func homecatalogs() -> [Catalognames] {
        let fm = FileManager.default
        if let atpathURL = Homepath().userHomeDirectoryURLPath {
            var catalogs = [Catalognames]()
            do {
                for filesandfolders in try
                    fm.contentsOfDirectory(at: atpathURL, includingPropertiesForKeys: nil)
                    where filesandfolders.hasDirectoryPath
                {
                    catalogs.append(Catalognames(filesandfolders.lastPathComponent))
                }
                return catalogs
            } catch {
                return []
            }
        }
        return []
    }
}
