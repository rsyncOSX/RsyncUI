//
//  DetailsOneTaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 15/05/2024.
//

import Foundation
import SwiftUI

struct DetailsOneTaskView: View {
    let remotedatanumbers: RemoteDataNumbers

    var body: some View {
        DetailsView(estimatedtask: remotedatanumbers, outputfromrsync: outputfromrsync)
    }

    var outputfromrsync: ObservableOutputfromrsync {
        let data = ObservableOutputfromrsync()
        data.generateoutput(remotedatanumbers.outputfromrsync)
        return data
    }
}
