//
//  NavigationOutputRsyncView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2023.
//

import SwiftUI

@available(macOS 14.0, *)
struct NavigationOutputRsyncView: View {
    @State private var outputfromrsync = Outputfromrsync()

    var output: [String]

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
            outputfromrsync.generatedata(output)
        }
    }
}
