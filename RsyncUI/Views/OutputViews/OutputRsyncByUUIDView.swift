//
//  OutputRsyncByUUIDView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/05/2024.
//

import SwiftUI

struct OutputRsyncByUUIDView: View {
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @State private var outputfromrsync = ObservableOutputfromrsync()

    let estimatedtask: RemoteDataNumbers
    let data: [String]

    var body: some View {
        DetailsView(estimatedtask: estimatedtask, outputfromrsync: outputfromrsync)
            .onAppear {
                outputfromrsync.generateoutput(data)
            }
            .onChange(of: selecteduuids) {
                outputfromrsync.output.removeAll()
                outputfromrsync.generateoutput(data)
            }
    }
}
