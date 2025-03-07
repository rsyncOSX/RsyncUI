//
//  HomeCatalogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/12/2023.
//

import SwiftUI

struct Catalognames: Identifiable {
    let id = UUID()
    var catalogname: String?

    init(_ name: String) {
        catalogname = name
    }
}

struct AttachedVolumes: Identifiable {
    let id = UUID()
    var volumename: URL?

    init(_ volumename: URL) {
        self.volumename = volumename
    }
}

struct HomeCatalogsView: View {
    @Bindable var newdata: ObservableAddConfigurations
    @Binding var path: [AddTasks]

    @State private var selecteduuid: Catalognames.ID?
    @State private var selectedAttachedVolume: AttachedVolumes.ID?

    var body: some View {
        HStack {
            Table(homecatalogs, selection: $selecteduuid) {
                TableColumn("Catalogs") { catalog in
                    Text(catalog.catalogname ?? "")
                }
            }

            Table(attachedVolumes, selection: $selectedAttachedVolume) {
                TableColumn("Attached Volumes") { volume in
                    Text(volume.volumename?.path() ?? "")
                }
            }
        }
        .onDisappear(perform: {
            var catalog = ""
            if let index = homecatalogs.firstIndex(where: { $0.id == selecteduuid }) {
                if let selectedcatalog = homecatalogs[index].catalogname {
                    catalog = selectedcatalog
                    newdata.localcatalog = newdata.localhome + "/" + selectedcatalog
                    newdata.backupID = "Backup of: " + selectedcatalog
                }
            }
            guard newdata.localcatalog.isEmpty == false else { return }
            if let index = attachedVolumes.firstIndex(where: { $0.id == selectedAttachedVolume }) {
                if let selectedvolume = attachedVolumes[index].volumename?.path() {
                    newdata.remotecatalog = selectedvolume + catalog
                }
            } else {
                newdata.remotecatalog = "/mounted_Volume/" + catalog
            }
        })

        var homecatalogs: [Catalognames] {
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

        var attachedVolumes: [AttachedVolumes] {
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
}
