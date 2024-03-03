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

    let homecatalogs: [Catalognames]
    let attachedVolumes: [AttachedVolumes]

    var body: some View {
        HStack {
            Table(homecatalogs, selection: $selecteduuid) {
                TableColumn("Catalogs") { catalog in
                    Text(catalog.catalogname ?? "")
                }
            }
            .onChange(of: selecteduuid) {
                let names = homecatalogs.filter { $0.id == selecteduuid }
                if names.count == 1 {
                    catalog = names[0].catalogname ?? ""
                }
                path.removeAll()
            }

            Table(attachedVolumes, selection: $selectedAttachedVolume) {
                TableColumn("Attached Volumes") { volume in
                    Text(volume.volumename?.path() ?? "")
                }
            }
            .onChange(of: selectedAttachedVolume) {
                let volume = attachedVolumes.filter { $0.id == selectedAttachedVolume }
                if volume.count == 1 {
                    if let volume = volume[0].volumename?.path() {
                        // attachedvolume = volume
                    }
                }
            }
        }
    }
}
