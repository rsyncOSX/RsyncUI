//
//  HomeCatalogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/12/2023.
//

import SwiftUI

struct Catalognames: Identifiable, Hashable {
    let id = UUID()
    var catalogname: String

    init(_ name: String) {
        catalogname = name
    }
}

struct AttachedVolumes: Identifiable, Hashable {
    let id = UUID()
    var volumename: URL

    init(_ name: URL) {
        volumename = name
    }
}

struct AttachedVolumeCatalogs: Identifiable, Hashable {
    let id = UUID()
    var catalogname: String

    init(_ name: String) {
        catalogname = name
    }
}

struct HomeCatalogsView: View {
    @Bindable var newdata: ObservableAddConfigurations
    @Binding var path: [AddTasks]

    @State private var selecteduuid: Catalognames.ID?
    @State private var selectedAttachedVolume: AttachedVolumes.ID?
    @State private var selectedAttachedVolumeCatalogs: AttachedVolumeCatalogs.ID?

    let homecatalogs: [Catalognames]
    let attachedVolumes: [AttachedVolumes]

    var body: some View {
        VStack(alignment: .leading) {
            Picker("", selection: $selecteduuid) {
                Text("Select a Folder")
                    .tag(nil as Catalognames.ID?)
                ForEach(homecatalogs, id: \.self) { catalog in
                    Text(catalog.catalogname)
                        .tag(catalog.id)
                }
            }
            .frame(width: 300)

            Picker("", selection: $selectedAttachedVolume) {
                Text("Select a Attached Volume")
                    .tag(nil as AttachedVolumes.ID?)
                ForEach(attachedVolumes, id: \.self) { volume in
                    Text(volume.volumename.absoluteString)
                        .tag(volume.id)
                }
            }
            .frame(width: 300)

            Picker("", selection: $selectedAttachedVolumeCatalogs) {
                Text("Select a Catalog")
                    .tag(nil as AttachedVolumeCatalogs.ID?)
                ForEach(attachedVolumesCatalogs, id: \.self) { catalog in
                    Text(catalog.catalogname)
                        .tag(catalog.id)
                }
            }
            .frame(width: 300)
        }
        .onDisappear(perform: {
            if let index = homecatalogs.firstIndex(where: { $0.id == selecteduuid }) {
                let selectedcatalog = homecatalogs[index].catalogname
                newdata.localcatalog = newdata.localhome.appending("/") + selectedcatalog
                newdata.backupID = "Backup of: " + selectedcatalog
            }

            guard newdata.localcatalog.isEmpty == false else { return }

            if let index = attachedVolumes.firstIndex(where: { $0.id == selectedAttachedVolume }) {
                let attachedvolume = attachedVolumes[index].volumename
                if let index = attachedVolumesCatalogs.firstIndex(where: { $0.id == selectedAttachedVolumeCatalogs }) {
                    let selectedvolume = (attachedvolume.relativePath).appending("/") + attachedVolumesCatalogs[index].catalogname
                    newdata.remotecatalog = selectedvolume
                }
            }
        })

        var attachedVolumesCatalogs: [AttachedVolumeCatalogs] {
            if let index = attachedVolumes.firstIndex(where: { $0.id == selectedAttachedVolume }) {
                let fm = FileManager.default
                let atpathURL = attachedVolumes[index].volumename
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
            return []
        }
    }
}
