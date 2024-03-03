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
    @Binding var catalog: String
    @Binding var attachedvolume: String
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
        .toolbar {
            ToolbarItem {
                Button {
                    if let index = homecatalogs.firstIndex(where: { $0.id == selecteduuid }) {
                        if let selectedcatalog = homecatalogs[index].catalogname {
                            catalog = selectedcatalog
                        }
                    }
                    print(selecteduuid)
                    print(selectedAttachedVolume)
                    if let index = attachedVolumes.firstIndex(where: { $0.id == selectedAttachedVolume }) {
                        if let selectedvolume = attachedVolumes[index].volumename?.path() {
                            attachedvolume = selectedvolume
                        }
                    }
                    path.removeAll()
                } label: {
                    Image(systemName: "return")
                }
                .help("Select home catalog")
            }
        }
    }

    var homecatalogs: [Catalognames] {
        if let atpath = NamesandPaths(.configurations).userHomeDirectoryPath {
            var catalogs = [Catalognames]()
            do {
                for folders in try Folder(path: atpath).subfolders {
                    catalogs.append(Catalognames(folders.name))
                }
                return catalogs
            } catch {
                return []
            }
        }
        return []
    }

    var attachedVolumes: [AttachedVolumes] {
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeIsRemovableKey, .volumeIsEjectableKey]
        let paths = FileManager().mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [])
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
