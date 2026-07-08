//
//  OpencatalogView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/03/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct OpencatalogView: View {
    @Binding var selecteditem: String
    @State private var isImporting: Bool = false
    let catalogs: Bool

    var body: some View {
        Button {
            isImporting = true
        } label: {
            Label("Browse", systemImage: catalogs ? "folder" : "doc")
                .labelStyle(.iconOnly)
                .font(.system(size: 12))
                .frame(width: 28, height: 22)
        }
        .buttonStyle(.bordered)
        .help("Browse...")
        .fileImporter(isPresented: $isImporting,
                      allowedContentTypes: [uutype],
                      onCompletion: { result in
                          switch result {
                          case let .success(url):
                              selecteditem = url.relativePath
                          case let .failure(error):
                              SharedReference.shared.errorobject?.alert(error: error)
                          }
                      })
    }

    var uutype: UTType {
        if catalogs {
            .directory
        } else {
            .item
        }
    }
}
