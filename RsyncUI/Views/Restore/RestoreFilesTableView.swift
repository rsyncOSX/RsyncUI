//
//  RestoreFilesTableView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 05/06/2023.
//

import SwiftUI

struct RestoreFilesTableView: View {
    @State private var selectedid: RestoreFileRecord.ID?
    @Binding var filestorestore: String

    var datalist: [RestoreFileRecord]

    var body: some View {
        ZStack {
            Table(datalist, selection: $selectedid) {
                TableColumn("Filenames", value: \.filename)
            }
            .onChange(of: selectedid) { _ in
                let record = datalist.filter { $0.id == selectedid }
                guard record.count > 0 else { return }
                filestorestore = record[0].filename
            }
        }
    }
}
