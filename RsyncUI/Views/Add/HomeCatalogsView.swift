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

    let homecatalogs: [Catalognames]
    let attachedVolumes: [AttachedVolumes]

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
            if let index = attachedVolumes.firstIndex(where: { $0.id == selectedAttachedVolume }) {
                if let selectedvolume = attachedVolumes[index].volumename?.path() {
                    newdata.remotecatalog = selectedvolume + catalog
                }
            } else {
                newdata.remotecatalog = "/mounted_Volume/" + catalog
            }
        })
    }
}
