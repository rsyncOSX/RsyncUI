//
//  ImportView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/07/2024.
//

import SwiftUI

struct ImportView: View {
    @Binding var focusimport: Bool
    @State var filenameimport: String = ""

    var body: some View {
        VStack {
            OpencatalogView(catalog: $filenameimport, choosecatalog: false)

            // Reset hiddenID if import
            Button {
                guard filenameimport.isEmpty == false else { return }
                _ = ReadImportConfigurationsJSON(filenameimport)
                focusimport = false
            } label: {
                Image(systemName: "square.and.arrow.down")
                    .foregroundColor(Color(.blue))
            }
            .help("Import tasks")

            Button {
                focusimport = false
            } label: {
                Image(systemName: "clear")
                    .foregroundColor(Color(.blue))
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
    }
}
