//
//  OneTaskDetailsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import Foundation
import Observation
import OSLog
import RsyncProcess
import SwiftUI

struct OneTaskDetailsView: View {
    @Bindable var progressdetails: ProgressDetails
    @State private var estimateiscompleted = false
    @State private var remotedatanumbers: RemoteDataNumbers?

    let selecteduuids: Set<SynchronizeConfiguration.ID>
    let configurations: [SynchronizeConfiguration]

    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                if estimateiscompleted == true {
                    if let remotedatanumbers {
                        DetailsView(remotedatanumbers: remotedatanumbers)
                    }
                } else {
                    VStack {
                        // Only one task is estimated if selected, if more than one
                        // task is selected multiple estimation is selected. That is why
                        // that is why (uuid: selecteduuids.first)
                        if let config = getconfig(uuid: selecteduuids.first) {
                            Text("Estimating now: " + "\(config.backupID)")
                                .foregroundColor(.green)
                                .font(.title)
                        }

                        ProgressView()
                    }
                }
            }
        }
        .onAppear {
            var selectedconfig: SynchronizeConfiguration?
            let selected = configurations.filter { config in
                selecteduuids.contains(config.id)
            }
            if selected.count == 1 {
                selectedconfig = selected[0]
            }
            let arguments = ArgumentsSynchronize(config: selectedconfig)
                .argumentssynchronize(dryRun: true, forDisplay: false)
            guard arguments != nil else { return }

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
            // Must check valid rsync exists
            guard SharedReference.shared.norsync == false else { return }
            guard selectedconfig?.task != SharedReference.shared.halted else { return }

            let process = RsyncProcess(arguments: arguments,
                                       hiddenID: selectedconfig?.hiddenID ?? -1,
                                       handlers: handlers,
                                       usefilehandler: false)

            do {
                try process.executeProcess()
            } catch let e {
                let error = e
                SharedReference.shared.errorobject?.alert(error: error)
            }
        }
    }

    private func getconfig(uuid: UUID?) -> SynchronizeConfiguration? {
        if let index = configurations.firstIndex(where: { $0.id == uuid }) {
            return configurations[index]
        }
        return nil
    }

    func validatetagging(_ lines: Int, _ tagged: Bool) throws {
        if lines > SharedReference.shared.alerttagginglines, tagged == false {
            throw ErrorDatatoSynchronize.thereisdatatosynchronize(idwitherror: "Current Synchronization ID")
        }
    }

    func processtermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        var selectedconfig: SynchronizeConfiguration?
        let selected = configurations.filter { config in
            selecteduuids.contains(config.id)
        }
        if selected.count == 1 {
            selectedconfig = selected[0]
        }

        if (stringoutputfromrsync?.count ?? 0) > 20, let stringoutputfromrsync {
            let suboutput = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)
            remotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: suboutput,
                                                  config: selectedconfig)
        } else {
            remotedatanumbers = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                                  config: selectedconfig)
        }

        // Validate that tagging is correct
        do {
            try validatetagging(stringoutputfromrsync?.count ?? 0, remotedatanumbers?.datatosynchronize ?? true)
        } catch let e {
            let error = e
            SharedReference.shared.errorobject?.alert(error: error)
        }

        Task {
            remotedatanumbers?.outputfromrsync = await ActorCreateOutputforView().createaoutputforview(stringoutputfromrsync)

            if let remotedatanumbers {
                progressdetails.appendrecordestimatedlist(remotedatanumbers)
            }

            estimateiscompleted = true
        }
    }
}
