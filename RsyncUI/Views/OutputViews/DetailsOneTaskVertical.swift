//
//  DetailsOneTaskVertical.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 15/05/2024.
//

import Foundation
import SwiftUI

struct DetailsOneTaskVertical: View {
    let estimatedtask: RemoteDataNumbers

    var body: some View {
        DetailsView(estimatedtask: estimatedtask, outputfromrsync: outputfromrsync)
    }

    var outputfromrsync: ObservableOutputfromrsync {
        let data = ObservableOutputfromrsync()
        data.generateoutput(estimatedtask.outputfromrsync)
        return data
    }
}
