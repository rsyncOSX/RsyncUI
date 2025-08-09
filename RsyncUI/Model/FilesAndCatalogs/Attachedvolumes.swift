//
//  Attachedvolumes.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 09/08/2025.
//

import Foundation

struct AttachedVolumes: Identifiable, Hashable {
    let id = UUID()
    var volumename: URL

    init(_ name: URL) {
        volumename = name
    }
}

struct Attachedvolumes: Sendable {
    func attachedVolumes() -> [AttachedVolumes] {
        let keys: [URLResourceKey] = [.volumeNameKey,
                                      .volumeIsRemovableKey,
                                      .volumeIsEjectableKey]
        let paths = FileManager()
            .mountedVolumeURLs(includingResourceValuesForKeys: keys,
                               options: [])
        var volumesarray = [AttachedVolumes]()
        if let urls = paths {
            for url in urls {
                let components = url.pathComponents
                if components.count > 1, components[1] == "Volumes" {
                    volumesarray.append(AttachedVolumes(url))
                }
            }
        }
        if volumesarray.count > 0 {
            return volumesarray
        } else {
            return []
        }
    }
}
