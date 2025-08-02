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

struct HomeCatalogsView: View {
    @Bindable var newdata: ObservableAddConfigurations
    @Binding var path: [AddTasks]

    @State private var selectedhomecatalog: Catalognames.ID?
    @State private var selectedAttachedVolume: AttachedVolumes.ID?
    @State private var selectedAttachedVolumeCatalogs: Catalognames.ID?

    let homecatalogs: [Catalognames]
    let attachedVolumes: [AttachedVolumes]

    var body: some View {
        VStack(alignment: .leading) {
            
            Spacer()
            
            Picker("Step one: select a Folder in home directory", selection: $selectedhomecatalog) {
                Text("Select")
                    .tag(nil as Catalognames.ID?)
                ForEach(homecatalogs, id: \.self) { catalog in
                    Text(catalog.catalogname)
                        .tag(catalog.id)
                }
            }
            .frame(width: 500)

            Picker("Step two: select an Attached Volume", selection: $selectedAttachedVolume) {
                Text("Select")
                    .tag(nil as AttachedVolumes.ID?)
                ForEach(attachedVolumes, id: \.self) { volume in
                    Text(volume.volumename.absoluteString)
                        .tag(volume.id)
                }
            }
            .frame(width: 500)

            Picker("Step three: select a Folder in Attached Volume", selection: $selectedAttachedVolumeCatalogs) {
                Text("Select")
                    .tag(nil as Catalognames.ID?)
                ForEach(attachedVolumesCatalogs, id: \.self) { catalog in
                    Text(catalog.catalogname)
                        .tag(catalog.id)
                }
            }
            .frame(width: 300)
            .disabled(selectedAttachedVolume == nil)
            
            Spacer()
            
        }
        .onDisappear(perform: {
            if let index = homecatalogs.firstIndex(where: { $0.id == selectedhomecatalog }) {
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

        var attachedVolumesCatalogs: [Catalognames] {
            if let index = attachedVolumes.firstIndex(where: { $0.id == selectedAttachedVolume }) {
                let fm = FileManager.default
                let atpathURL = attachedVolumes[index].volumename
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
}
