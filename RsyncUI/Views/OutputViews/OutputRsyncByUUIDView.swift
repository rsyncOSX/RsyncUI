//
//  OutputRsyncByUUIDView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/05/2024.
//

import SwiftUI

struct OutputRsyncByUUIDView: View {
    @Bindable var estimateprogressdetails: EstimateProgressDetails
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @State private var outputfromrsync = ObservableOutputfromrsync()
    @State private var output: [String]

    var body: some View {
        VStack {
            Table(outputfromrsync.output) {
                TableColumn("Output") { data in
                    Text(data.line)
                }
            }
        }
        .padding()
        .onAppear {
            if let index = estimateprogressdetails.estimatedlist?.firstIndex(where: { $0.id == selecteduuids.first }) {
                output = estimateprogressdetails.estimatedlist?[index].outputfromrsync ?? []
            } else {
                output = []
            }
            outputfromrsync.generateoutput(output)
        }
    }
}
