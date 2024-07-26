//
//  OpencatalogView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 09/11/2021.
//

import SwiftUI

struct OpencatalogView: View {
    @Binding var catalog: String

    var choosecatalog: Bool

    var body: some View {
        HStack {
            Button {
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = choosecatalog
                panel.canChooseFiles = !choosecatalog
                if panel.runModal() == .OK {
                    catalog = panel.url?.path ?? ""
                }
            } label: {
                Image(systemName: "folder")
            }
            .buttonStyle(ColorfulButtonStyle())
            .help("Select catalog or file")
        }
    }
}
