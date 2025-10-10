//
//  HomeCatalogsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/12/2023.
//

import Foundation
import Observation
import SwiftUI

struct HomeCatalogsView: View {
    @Bindable var newdata: ObservableAddConfigurations
    @Binding var path: [AddTasks]

    @State private var selectedhomecatalog: Catalognames.ID?
    @State private var selectedAttachedVolume: AttachedVolumes.ID?
    @State private var selectedAttachedVolumeCatalogs: String?

    let homecatalogs: [Catalognames]
    let attachedVolumes: [AttachedVolumes]

    var body: some View {
        Form {
            Section(header: Text("Step one")
                .font(.title3)
                .fontWeight(.bold))
            {
                Picker("Select a Folder in home directory", selection: $selectedhomecatalog) {
                    Text("Select")
                        .tag(nil as Catalognames.ID?)
                    ForEach(homecatalogs, id: \.self) { catalog in
                        Text(catalog.catalogname)
                            .tag(catalog.id)
                    }
                }
                .frame(width: 500)
            }

            Section(header: Text("Step two and three")
                .font(.title3)
                .fontWeight(.bold))
            {
                Picker("Select an Attached Volume", selection: $selectedAttachedVolume) {
                    Text("Select")
                        .tag(nil as AttachedVolumes.ID?)
                    ForEach(attachedVolumes, id: \.self) { volume in
                        Text(volume.volumename.lastPathComponent)
                            .tag(volume.id)
                    }
                }
                .frame(width: 500)

                Picker("Select a Folder in Attached Volume", selection: $selectedAttachedVolumeCatalogs) {
                    Text("Select")
                        .tag(nil as String?)
                    ForEach(attachedVolumesCatalogs, id: \.self) { volumename in
                        Text(volumename)
                            .tag(volumename)
                    }
                }
                .frame(width: 500)
                .disabled(selectedAttachedVolume == nil)
            }

            Section(header: Text("Step four")
                .font(.title3)
                .fontWeight(.bold))
            {
                Button("Return") {
                    path.removeAll()
                }
                .buttonStyle(ColorfulButtonStyle())
            }
        }
        .formStyle(.grouped)
        .onDisappear {
            if let index = homecatalogs.firstIndex(where: { $0.id == selectedhomecatalog }) {
                let selectedcatalog = homecatalogs[index].catalogname
                newdata.localcatalog = newdata.localhome.appending("/") + selectedcatalog
                newdata.backupID = "Backup of: " + selectedcatalog
            }

            guard newdata.localcatalog.isEmpty == false else { return }

            if let index = attachedVolumes.firstIndex(where: { $0.id == selectedAttachedVolume }) {
                let attachedvolume = attachedVolumes[index].volumename
                if let index = attachedVolumesCatalogs.firstIndex(where: { $0 == selectedAttachedVolumeCatalogs }) {
                    let selectedvolume = (attachedvolume.relativePath).appending("/") + attachedVolumesCatalogs[index]
                    newdata.remotecatalog = selectedvolume
                }
            }
        }
        .padding()

        var attachedVolumesCatalogs: [String] {
            if let index = attachedVolumes.firstIndex(where: { $0.id == selectedAttachedVolume }) {
                let fm = FileManager.default
                let atpathURL = attachedVolumes[index].volumename
                var catalogs = [String]()
                do {
                    for filesandfolders in try
                        fm.contentsOfDirectory(at: atpathURL, includingPropertiesForKeys: nil)
                        where filesandfolders.hasDirectoryPath
                    {
                        catalogs.append(filesandfolders.lastPathComponent)
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
