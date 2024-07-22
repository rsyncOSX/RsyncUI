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
    @State var exportcatalog: String = ""
    @State var filenameexport: String = ""

    let configurations: [SynchronizeConfiguration]
    let profile: String?

    var body: some View {
        VStack {
            ListofTasksLightView(selecteduuids: $selecteduuids, profile: profile, configurations: configurations)

            HStack {
                Button {
                    let path = exportcatalog + "/" + filenameexport
                    guard exportcatalog.isEmpty == false && filenameexport.isEmpty == false else {
                        focusexport = false
                        return
                    }
                    _ = WriteExportConfigurationsJSON(path, configurations)
                    focusexport = false
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }

                OpencatalogView(catalog: $exportcatalog, choosecatalog: true)

                setfilename
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
}
