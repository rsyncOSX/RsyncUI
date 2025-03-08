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

struct AttachedVolumeCatalogs {
    var catalogname: String

    init(_ name: String) {
        catalogname = name
    }
}

extension AttachedVolumeCatalogs: Identifiable {
    var id: String {
        catalogname
    }
}

struct HomeCatalogsView: View {
    @Bindable var newdata: ObservableAddConfigurations
    @Binding var path: [AddTasks]

    @State private var selecteduuid: Catalognames.ID?
    @State private var selectedAttachedVolume: AttachedVolumes.ID?
    @State private var selectedAttachedVolumeCatalogs: String?

    let homecatalogs: [Catalognames]
    let attachedVolumes: [AttachedVolumes]

    var body: some View {
        HStack {
            Table(homecatalogs, selection: $selecteduuid) {
                TableColumn("Catalogs") { catalog in
                    Text(catalog.catalogname ?? "")
                }
            }

            VStack {
                Table(attachedVolumes, selection: $selectedAttachedVolume) {
                    TableColumn("Attached Volumes") { volume in
                        Text(volume.volumename?.path() ?? "")
                    }
                }

                Table(attachedVolumesCatalogs, selection: $selectedAttachedVolumeCatalogs) {
                    TableColumn("Attached Volume Catalogs") { catalog in
                        Text(catalog.catalogname)
                    }
                }
                .overlay {
                    if attachedVolumesCatalogs.isEmpty {
                        ContentUnavailableView {
                            Label("Select an Attached Volume",
                                  systemImage: "folder")
                        } description: {}
                    }
                }
            }
        }
        .onDisappear(perform: {
            if let index = homecatalogs.firstIndex(where: { $0.id == selecteduuid }) {
                if let selectedcatalog = homecatalogs[index].catalogname {
                    newdata.localcatalog = newdata.localhome + "/" + selectedcatalog
                    newdata.backupID = "Backup of: " + selectedcatalog
                }
            }

            guard newdata.localcatalog.isEmpty == false else { return }

            if let index = attachedVolumes.firstIndex(where: { $0.id == selectedAttachedVolume }) {
                let attachedvolume = attachedVolumes[index].volumename
                if let index = attachedVolumesCatalogs.firstIndex(where: { $0.catalogname == selectedAttachedVolumeCatalogs }) {
                    let selectedvolume = (attachedvolume?.relativePath ?? "") + "/" + attachedVolumesCatalogs[index].catalogname
                    newdata.remotecatalog = selectedvolume
                }
            }
        })

        var attachedVolumesCatalogs: [AttachedVolumeCatalogs] {
            if let index = attachedVolumes.firstIndex(where: { $0.id == selectedAttachedVolume }) {
                let fm = FileManager.default
                if let atpathURL = attachedVolumes[index].volumename {
                    var catalogs = [AttachedVolumeCatalogs]()
                    do {
                        for filesandfolders in try
                            fm.contentsOfDirectory(at: atpathURL, includingPropertiesForKeys: nil)
                            where filesandfolders.hasDirectoryPath
                        {
                            catalogs.append(AttachedVolumeCatalogs(filesandfolders.lastPathComponent))
                        }
                        return catalogs
                    } catch {
                        return []
                    }
                }
            }
            return []
        }
    }
}
