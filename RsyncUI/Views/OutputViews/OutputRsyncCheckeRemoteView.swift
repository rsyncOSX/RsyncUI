//
//  OutputRsyncCheckeRemoteView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2024.
//

import SwiftUI

struct OutputRsyncCheckeRemoteView: View {
    @State private var progress = true
    // Pull data fraom remote
    @State private var pullremotedatanumbers: RemoteDataNumbers?
    // Push data from local to remote
    @State private var pushremotedatanumbers: RemoteDataNumbers?

    let config: SynchronizeConfiguration

    var body: some View {
        HStack {
            if progress {
                Spacer()

                ProgressView()

                Spacer()

            } else {
                if let pullremotedatanumbers {
                    HStack {
                        DetailsView(remotedatanumbers: pullremotedatanumbers)
                        DetailsView(remotedatanumbers: pullremotedatanumbers)
                    }
                }
            }
        }
        .onAppear {
            pullremote(config: config)
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
    func pullremote(config: SynchronizeConfiguration) {
        let arguments = ArgumentsPullRemote(config: config).argumentspullremotewithparameters(dryRun: true,
                                                                                                  forDisplay: false)
        let process = ProcessRsync(arguments: arguments,
                                   config: config,
                                   processtermination: processtermination)
        process.executeProcess()
    }

    func processtermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        progress = false
        pullremotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                              config: config)
    }

    func abort() {
        _ = InterruptProcess()
    }
}
