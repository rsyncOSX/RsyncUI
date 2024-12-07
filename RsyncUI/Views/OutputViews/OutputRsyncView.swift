//
//  OutputRsyncView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2023.
//

import SwiftUI

struct OutputRsyncView: View {
    var output: [RsyncOutputData]

    var body: some View {
        Table(output) {
            TableColumn("Output from rsync" + " \(output.count) lines") { data in
                Text(data.record)
            }
        }
        .padding()
    }
}
