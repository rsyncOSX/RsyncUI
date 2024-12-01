//
//  OutputRsyncVerifyView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2024.
//

import SwiftUI

struct OutputRsyncVerifyView: View {
    @State private var progress = true
    @State private var remotedatanumbers: RemoteDataNumbers?

    let config: SynchronizeConfiguration

    var body: some View {
        HStack {
            if progress {
                Spacer()

                ProgressView()

                Spacer()

            } else {
                if let remotedatanumbers {
                    DetailsView(remotedatanumbers: remotedatanumbers)
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

    // For a verify run, --dry-run
    func verify(config: SynchronizeConfiguration) {
        let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: true,
                                                                                  forDisplay: false)
        let process = ProcessRsync(arguments: arguments,
                                   config: config,
                                   processtermination: processtermination)
        process.executeProcess()
    }

    func processtermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        progress = false
        remotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                              config: config)
    }

    func abort() {
        InterruptProcess()
    }
}
