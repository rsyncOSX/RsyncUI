//
//  DetailsVerifyView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2024.
//

import SwiftUI

struct DetailsVerifyView: View {
    let remotedatanumbers: RemoteDataNumbers

    var body: some View {
        Table(remotedatanumbers.outputfromrsync ?? []) {
            TableColumn("Output from rsync" + ": \(remotedatanumbers.outputfromrsync?.count ?? 0) rows") { data in
                if data.record.contains("*deleting") {
                    HStack {
                        Text("delete").foregroundColor(.red)
                        Text(data.record)
                    }

                } else if data.record.contains("<") {
                    HStack {
                        Text("push").foregroundColor(.blue)
                        Text(data.record)
                    }

                } else if data.record.contains(">") {
                    HStack {
                        Text("pull").foregroundColor(.green)
                        Text(data.record)
                    }
                } else {
                    Text(data.record)
                }
            }
        }
    }
}
