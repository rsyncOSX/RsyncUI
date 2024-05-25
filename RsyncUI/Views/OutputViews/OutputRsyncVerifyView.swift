//
//  OutputRsyncVerifyView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2024.
//

import SwiftUI

struct OutputRsyncVerifyView: View {
    @State private var outputromrsync = ObservableOutputfromrsync()
    @State private var progress = false

    let config: SynchronizeConfiguration

    var body: some View {
        ZStack {
            Table(outputromrsync.output) {
                TableColumn("Output from rsync") { data in
                    Text(data.line)
                }
            }

            if progress {
                ProgressView()
            }
        }
        .onAppear {
            progress = true
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

        func processtermination(data: [String]?, hiddenID _: Int?) {
            progress = false
            outputromrsync.generateoutput(data)
        }

        func abort() {
            _ = InterruptProcess()
        }
    }
}
