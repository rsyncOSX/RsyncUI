//
//  DetailsVerifyView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2024.
//

import SwiftUI

struct DetailsVerifyView: View {
    let remotedatanumbers: RemoteDataNumbers
    let text: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(text)
                .font(.title2)
                .padding()

            Table(remotedatanumbers.outputfromrsync ?? []) {
                TableColumn("Output from rsync" + ": \(remotedatanumbers.outputfromrsync?.count ?? 0) rows") { data in
                    Text(data.record)
                }
            }
        }
    }
}
