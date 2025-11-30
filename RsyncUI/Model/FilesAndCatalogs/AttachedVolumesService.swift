//
//  Attachedvolumes.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 09/08/2025.
//

import Foundation

struct AttachedVolume: Identifiable, Hashable {
    var id: URL { volumeURL }
    let volumeURL: URL
    
    init(_ url: URL) {
        volumeURL = url
    }
}

struct AttachedVolumesService: Sendable {
    func attachedVolumes() -> [AttachedVolume] {
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeIsRemovableKey,
            .volumeIsEjectableKey
        ]
        
        guard let paths = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: []
        ) else {
            return []
        }
        
        return paths
            .filter { url in
                let components = url.pathComponents
                return components.count > 1 && components[1] == "Volumes"
            }
            .map { AttachedVolume($0) }
    }
}
