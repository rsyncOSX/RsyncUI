//
//  OutputRsyncVerifyView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2024.
//

import SwiftUI

@MainActor
struct OutputRsyncVerifyView: View {
    @State private var outputromrsync = Outputfromrsync()

    let config: SynchronizeConfiguration
    let selectedrsynccommand: RsyncCommand

    var body: some View {
        Table(outputromrsync.output) {
            TableColumn("Output") { data in
                Text(data.line)
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
        switch selectedrsynccommand {
        case .synchronize:
            arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: true, forDisplay: false)
        case .restore:
            arguments = ArgumentsRestore(config: config,
                                         restoresnapshotbyfiles: false).argumentsrestore(dryRun: true, forDisplay: false, tmprestore: true)
        case .verify:
            arguments = ArgumentsVerify(config: config).argumentsverify(forDisplay: false)
        }
        let process = RsyncProcessFilehandler(arguments: arguments,
                                              config: config,
                                              processtermination: processtermination,
                                              filehandler: filehandler)
        process.executeProcess()

        func processtermination(data: [String]?, hiddenID _: Int?) {
            outputromrsync.generateoutput(data)
        }

        func filehandler(count _: Int) {}

        func abort() {
            _ = InterruptProcess()
        }
    }
}
