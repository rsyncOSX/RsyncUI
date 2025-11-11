//
//  VerifyTasks.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 09/05/2025.
//

import OSLog
import RsyncProcess
import SwiftUI

struct VerifyTasks: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations

    @State private var remotedatanumbers: RemoteDataNumbers?
    @State private var selectedconfig: SynchronizeConfiguration?
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    // Present arguments view
    @State private var presentestimates: Bool = false
    // Estimating
    @State private var estimating: Bool = false
    // Show warning
    @State private var showmessage: Bool = true

    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    ListofTasksAddView(rsyncUIdata: rsyncUIdata,
                                       selecteduuids: $selecteduuids)
                        .onChange(of: selecteduuids) {
                            if let configurations = rsyncUIdata.configurations {
                                if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                                    selectedconfig = configurations[index]

                                } else {
                                    selectedconfig = nil
                                }
                            }
                        }

                    if estimating {
                        ProgressView()
                    }

                    if showmessage {
                        Text("Verify task **always** include the --dry-run parameter")
                            .foregroundColor(.blue)
                            .font(.title)
                            .onAppear {
                                Task {
                                    try await Task.sleep(seconds: 3)
                                    showmessage = false
                                }
                            }
                    }
                }

                HStack {
                    Text("Select a task and select the ")

                    Text(Image(systemName: "play.fill"))

                    Text(" on the toolbar to verify a task")
                }
            }
            .toolbar(content: {
                if selectedconfig != nil,
                   selectedconfig?.task != SharedReference.shared.halted
                {
                    ToolbarItem {
                        Button {
                            if let selectedconfig {
                                estimating = true
                                verify(config: selectedconfig)
                            }
                        } label: {
                            Image(systemName: "play.fill")
                        }
                        .help("Verify task")
                    }
                }

                if selectedconfig != nil,
                   selectedconfig?.task != SharedReference.shared.halted
                {
                    ToolbarItem {
                        Button {
                            abort()
                        } label: {
                            Image(systemName: "stop.fill")
                        }
                        .help("Abort (⌘K)")
                    }
                }

            })
            .navigationTitle("Verify tasks - dry-run parameter is enabled")
            .navigationDestination(isPresented: $presentestimates) {
                if let remotedatanumbers {
                    DetailsView(remotedatanumbers: remotedatanumbers)
                }
            }
        }
    }

    // For a verify run, --dry-run
    func verify(config: SynchronizeConfiguration) {
        let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: true,
                                                                                  forDisplay: false)
        let handlers = ProcessHandlers(
            processtermination: processtermination,
            filehandler: { _ in
                Logger.process.info("RsyncProcess:You should not SEE this message")
            },
            rsyncpath: GetfullpathforRsync().rsyncpath,
            checklineforerror: TrimOutputFromRsync().checkforrsyncerror,
            updateprocess: SharedReference.shared.updateprocess,
            propogateerror: { error in
                SharedReference.shared.errorobject?.alert(error: error)
            },
            logger: { command, output in
                _ = await ActorLogToFile(command, output)
            },
            checkforerrorinrsyncoutput: SharedReference.shared.checkforerrorinrsyncoutput,
            rsyncversion3: SharedReference.shared.rsyncversion3,
            environment: MyEnvironment()?.environment
        )

        guard SharedReference.shared.norsync == false else { return }
        guard config.task != SharedReference.shared.halted else { return }

        let process = RsyncProcess(arguments: arguments,
                                   hiddenID: config.hiddenID,
                                   handlers: handlers,
                                   usefilehandler: false)
        do {
            try process.executeProcess()
        } catch let e {
            let error = e
            SharedReference.shared.errorobject?.alert(error: error)
        }
    }

    func processtermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        estimating = false

        if (stringoutputfromrsync?.count ?? 0) > 20, let stringoutputfromrsync {
            let suboutput = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)
            remotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: suboutput,
                                                  config: selectedconfig)
        } else {
            remotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                                  config: selectedconfig)
        }

        Task {
            remotedatanumbers?.outputfromrsync = await ActorCreateOutputforView().createaoutputforview(stringoutputfromrsync)
            presentestimates = true
        }
    }

    func abort() {
        InterruptProcess()
    }
}
