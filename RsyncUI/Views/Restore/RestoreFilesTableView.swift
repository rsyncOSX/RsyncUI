//
//  RestoreFilesTableView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 05/06/2023.
//

import SwiftUI

struct RestoreFilesTableView: View {
    @SwiftUI.Environment(ObserveableRestore.self) private var restore

    @State private var selectedid: RestoreFileRecord.ID?
    @Binding var filestorestore: String

    var body: some View {
        ZStack {
            Table(restore.datalist, selection: $selectedid.onChange {
                let record = restore.datalist.filter { $0.id == selectedid }
                guard record.count > 0 else { return }
                filestorestore = record[0].filename
            }) {
                TableColumn("Filenames", value: \.filename)
            }
        }
    }
}
