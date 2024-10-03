//
//  RestoreFilesTableView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 05/06/2023.
//

import SwiftUI

struct RestoreFilesTableView: View {
    @State private var selectedid: RsyncOutputData.ID?
    @Binding var filestorestore: String

    var datalist: [RsyncOutputData]

    var body: some View {
            Table(datalist, selection: $selectedid) {
                TableColumn("Filenames", value: \.line)
            }
            .onChange(of: selectedid) {
                let record = datalist.filter { $0.id == selectedid }
                guard record.count > 0 else { return }
                filestorestore = record[0].line
            }
        }
}
