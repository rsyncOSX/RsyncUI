//
//  OutputRsyncView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/10/2022.
//

import SwiftUI

struct OutputRsyncView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    @StateObject var outputfromrsync = Outputfromrsync()

    var output: [String]

    var body: some View {
        VStack {
            Text("Output from rsync")
                .font(.title2)
                .padding()

            Table(outputfromrsync.output) {
                TableColumn("Output") { data in
                    Text(data.line)
                }
                .width(min: 700)
            }

            Spacer()

            HStack {
                Spacer()

                Button("Dismiss") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            outputfromrsync.generatedata(output)
        }
    }
}
