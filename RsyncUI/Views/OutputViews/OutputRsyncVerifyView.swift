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
    let checkremote: Bool

    var body: some View {
        HStack {
            if progress {
                Spacer()

                ProgressView()

                Spacer()

            } else {
                if let remotedatanumbers, checkremote == false{
                    DetailsView(remotedatanumbers: remotedatanumbers, checkremote: checkremote)
                } else {
                    HStack {
                        if let remotedatanumbers {
                            DetailsView(remotedatanumbers: remotedatanumbers, checkremote: checkremote)
                            DetailsView(remotedatanumbers: remotedatanumbers, checkremote: checkremote)
                        }
                    }
                }
            }
        }
        .onAppear {
            if checkremote {
                getremote(config: config)
            } else {
                verify(config: config)
            }
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
