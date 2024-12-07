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
        Task {
            remotedatanumbers?.outputfromrsync = await CreateOutputforviewOutputRsync().createoutputforviewoutputrsync(stringoutputfromrsync)
        }
    }

    func abort() {
        InterruptProcess()
    }
}

import OSLog

actor CreateOutputforviewOutputRsync {
    
    let maxcount = 40000

    func createoutputforviewoutputrsync (_ stringoutputfromrsync: [String]?)  async -> [RsyncOutputData] {
        Logger.process.info("createoutputforviewoutputrsync(): on main thread: \(Thread.isMain)")

        if let data = stringoutputfromrsync, data.count < maxcount {
            return data.map { line in
                RsyncOutputData(record: line)
            }
        } else if let data = stringoutputfromrsync {
            let suboutput = Array(data[0 ..< maxcount]) + Array(data[data.count - 20 ..< data.count])
            return  suboutput.map { line in
                RsyncOutputData(record: line)
            }
        }
        return []
    }
    
}
