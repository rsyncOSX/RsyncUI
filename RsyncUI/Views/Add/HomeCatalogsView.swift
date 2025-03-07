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
    @State private var selectedAttachedVolumeCatalogs: Catalognames.ID?

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
                        Text(catalog.catalogname ?? "")
                    }
                }
                .overlay {
                    if attachedVolumesCatalogs.isEmpty {
                        ContentUnavailableView {
                            Label("Select an Attached Volume",
                                  systemImage: "play.fill")
                        } description: {}
                    }
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
            if let index = attachedVolumesCatalogs.firstIndex(where: { $0.id == selectedAttachedVolumeCatalogs }) {
                if let selectedvolume = attachedVolumesCatalogs[index].catalogname {
                    newdata.remotecatalog = selectedvolume + catalog
                }
            } else {
                newdata.remotecatalog = "/mounted_Volume/" + catalog
            }
        })

        var attachedVolumesCatalogs: [Catalognames] {
            if let index = attachedVolumes.firstIndex(where: { $0.id == selectedAttachedVolume }) {
                let fm = FileManager.default
                if let atpathURL = attachedVolumes[index].volumename {
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
            return []
        }
    }
}
