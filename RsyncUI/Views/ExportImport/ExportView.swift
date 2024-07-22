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

    let configurations: [SynchronizeConfiguration]
    let profile: String?

    var body: some View {
        VStack {
            ListofTasksLightView(selecteduuids: $selecteduuids, profile: profile, configurations: configurations)

            HStack {
                Button {
                    let path = exportcatalog + "/export.json"
                    guard exportcatalog.isEmpty == false else {
                        focusexport = false
                        return
                    }
                    _ = WriteExportConfigurationsJSON(path, configurations)
                    focusexport = false
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }

                OpencatalogView(catalog: $exportcatalog, choosecatalog: true)
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
    }
}
