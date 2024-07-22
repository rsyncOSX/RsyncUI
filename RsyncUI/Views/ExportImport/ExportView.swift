//
//  ExportView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/07/2024.
//

import SwiftUI

struct ExportView: View {
    @Binding var focusexport: Bool
    @State var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State var exportcatalog: String = Homepath().userHomeDirectoryPath ?? ""
    @State var filenameexport: String = ""

    let configurations: [SynchronizeConfiguration]
    let profile: String?

    var body: some View {
        VStack {
            ListofTasksLightView(selecteduuids: $selecteduuids, profile: profile, configurations: configurations)

            HStack {
                setfilename

                OpencatalogView(catalog: $exportcatalog, choosecatalog: true)

                Button {
                    let path = exportcatalog + "/" + filenameexport + ".json"
                    guard exportcatalog.isEmpty == false && filenameexport.isEmpty == false else {
                        focusexport = false
                        return
                    }
                    _ = WriteExportConfigurationsJSON(path, selectedconfigurations())
                    focusexport = false
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }

                Button {
                    focusexport = false
                } label: {
                    Image(systemName: "xmark.circle")
                }
            }

            if exportcatalog.isEmpty == true && filenameexport.isEmpty == true {
                Text("Select catalog and add filename for export")
                    .labelStyle(.titleOnly)
            } else {
                if filenameexport.isEmpty == false {
                    Text(exportcatalog + "/" + filenameexport + ".json")
                        .foregroundColor(.secondary)
                } else {
                    Text(exportcatalog + "/")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
    }

    var setfilename: some View {
        EditValue(300, NSLocalizedString("Filename export", comment: ""),
                  $filenameexport)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    func selectedconfigurations() -> [SynchronizeConfiguration] {
        if selecteduuids.count > 0 {
            return configurations.filter { selecteduuids.contains($0.id) }
        } else {
            return configurations
        }
    }
}
