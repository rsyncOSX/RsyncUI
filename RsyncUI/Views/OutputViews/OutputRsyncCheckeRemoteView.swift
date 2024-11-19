//
//  OutputRsyncCheckeRemoteView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2024.
//

import SwiftUI

struct OutputRsyncCheckeRemoteView: View {
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
                    HStack {
                        DetailsView(remotedatanumbers: remotedatanumbers)
                        DetailsView(remotedatanumbers: remotedatanumbers)
                    }
                }
            }
        }
        .onAppear {
            getremote(config: config)
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

    // For check remote, pull remote data
    func getremote(config: SynchronizeConfiguration) {
        let arguments = ArgumentsVerifyRemote(config: config).argumentsverifyremotewithparameters(dryRun: true,
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
        _ = InterruptProcess()
    }
}
