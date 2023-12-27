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

struct HomeCatalogsView: View {
    @Binding var catalog: String
    @Binding var path: [AddTasks]
    @State private var selecteduuid: Catalognames.ID?

    let homecatalogs: [Catalognames]

    var body: some View {
        VStack {
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
        }
    }
}
