//
//  OutputRsyncView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2023.
//

import SwiftUI

struct OutputRsyncView: View {
    @State private var outputfromrsync = ObservableOutputfromrsync()

    var output: [RsyncOutputData]

    var body: some View {
        Table(output) {
            TableColumn("Output from rsync") { data in
                Text(data.line)
            }
        }
        .padding()
    }
}
