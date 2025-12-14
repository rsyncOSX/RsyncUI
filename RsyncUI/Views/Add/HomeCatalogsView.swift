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

    @State private var selectedhomecatalog: Catalog.ID?
    @State private var selectedAttachedVolume: AttachedVolume.ID?
    @State private var selectedAttachedVolumeCatalogs: String?

    let homecatalogs: [Catalog]
    let attachedVolumes: [AttachedVolume]

    var body: some View {
        Form {
            Section(header: Text("Step one")
                .font(.title3)
                .fontWeight(.bold)) {
                    Picker("Select a Folder in home directory", selection: $selectedhomecatalog) {
                        Text("Select")
                            .tag(nil as Catalog.ID?)
                        ForEach(homecatalogs, id: \.self) { catalog in
                            Text(catalog.name)
                                .tag(catalog.id)
                        }
                    }
                    .frame(width: 500)
                }

            Section(header: Text("Step two and three")
                .font(.title3)
                .fontWeight(.bold)) {
                    Picker("Select an Attached Volume", selection: $selectedAttachedVolume) {
                        Text("Select")
                            .tag(nil as AttachedVolume.ID?)
                        ForEach(attachedVolumes, id: \.self) { volume in
                            Text(volume.volumeURL.lastPathComponent)
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
                .fontWeight(.bold)) {
                    ConditionalGlassButton(
                        systemImage: "return",
                        text: "Return",
                        helpText: "Return"
                    ) {
                        path.removeAll()
                    }
                }
        }
        .formStyle(.grouped)
        .onDisappear {
            if let index = homecatalogs.firstIndex(where: { $0.id == selectedhomecatalog }) {
                let selectedcatalog = homecatalogs[index].name
                newdata.localcatalog = newdata.localhome + selectedcatalog
                newdata.backupID = "Backup of: " + selectedcatalog
            }

            guard newdata.localcatalog.isEmpty == false else { return }

            if let index = attachedVolumes.firstIndex(where: { $0.id == selectedAttachedVolume }) {
                let attachedvolume = attachedVolumes[index].volumeURL
                if let index = attachedVolumesCatalogs.firstIndex(where: { $0 == selectedAttachedVolumeCatalogs }) {
                    let selectedvolume = (attachedvolume.relativePath).appending("/") + attachedVolumesCatalogs[index]
                    newdata.remotecatalog = selectedvolume
                }
            }
        }
        .padding()

        var attachedVolumesCatalogs: [String] {
            if let index = attachedVolumes.firstIndex(where: { $0.id == selectedAttachedVolume }) {
                let fmanager = FileManager.default
                let atpathURL = attachedVolumes[index].volumeURL
                var catalogs = [String]()
                do {
                    for filesandfolders in try
                            fmanager.contentsOfDirectory(at: atpathURL, includingPropertiesForKeys: nil)
                        where filesandfolders.hasDirectoryPath {
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
