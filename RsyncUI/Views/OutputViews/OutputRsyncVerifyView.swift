//
//  OutputRsyncVerifyView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2024.
//

import SwiftUI

struct OutputRsyncVerifyView: View {
    @State private var outputfromrsync = ObservableOutputfromrsync()
    @State private var progress = true
    @State private var estimatedtask: RemoteDataNumbers?

    let config: SynchronizeConfiguration

    var body: some View {
        HStack {
            if progress {
                
                Spacer()
                
                ProgressView()
                
                Spacer()
                
            } else {
                if let estimatedtask {
                    DetailsView(estimatedtask: estimatedtask, outputfromrsync: outputfromrsync)
                }
            }
        }
        .onAppear {
            verify(config: config)
        }
        .toolbar(content: {
            ToolbarItem {
                Button {
                    abort()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .help("Abort (⌘K)")
            }
        })
    }

    func verify(config: SynchronizeConfiguration) {
        var arguments: [String]?
        arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: true,
                                                                              forDisplay: false)
        let process = RsyncProcessNOFilehandler(arguments: arguments,
                                                config: config,
                                                processtermination: processtermination)
        process.executeProcess()
    }

    func processtermination(data: [String]?, hiddenID _: Int?) {
        progress = false
        outputfromrsync.generateoutput(data)
        estimatedtask = RemoteDataNumbers(outputfromrsync: data,
                                          config: config)
    }

    func abort() {
        _ = InterruptProcess()
    }
}
