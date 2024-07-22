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
    @State var filenameexport: String = "export"

    let configurations: [SynchronizeConfiguration]
    let profile: String?

    var body: some View {
        VStack {
            ListofTasksLightView(selecteduuids: $selecteduuids, profile: profile, configurations: configurations)

            HStack {
                Text(exportcatalog)
                    .foregroundColor(.secondary)

                setfilename

                Text(".json")
                    .foregroundColor(.secondary)

                OpencatalogView(catalog: $exportcatalog, choosecatalog: true)

                Button {
                    var path = ""
                    if exportcatalog.hasSuffix("/") == true {
                        path = exportcatalog + filenameexport + ".json"
                    } else {
                        path = exportcatalog + "/" + filenameexport + ".json"
                    }
                    guard exportcatalog.isEmpty == false && filenameexport.isEmpty == false else {
                        focusexport = false
                        return
                    }
                    _ = WriteExportConfigurationsJSON(path, selectedconfigurations())
                    focusexport = false
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }

                Spacer()

                Button {
                    focusexport = false
                } label: {
                    Image(systemName: "xmark.circle")
                }
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            if FileManager.default.locationExists(at: exportcatalog + "/" + "tmp", kind: .folder) {
                exportcatalog += "/" + "tmp" + "/"
            } else {
                exportcatalog += "/"
            }
        }
    }

    var setfilename: some View {
        EditValue(150, NSLocalizedString("Filename export", comment: ""),
                  $filenameexport)
            .textContentType(.none)
    }

    func selectedconfigurations() -> [SynchronizeConfiguration] {
        if selecteduuids.count > 0 {
            return configurations.filter { selecteduuids.contains($0.id) && $0.task != SharedReference.shared.snapshot }
        } else {
            return configurations.filter { $0.task != SharedReference.shared.snapshot }
        }
    }
}
