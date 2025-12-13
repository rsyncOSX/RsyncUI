import OSLog
import RsyncProcess
import SwiftUI

extension QuicktaskView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem {
            Button {
                resetForm()
            } label: {
                if localcatalog.isEmpty == false {
                    Image(systemName: "clear")
                        .foregroundColor(Color(.red))
                } else {
                    Image(systemName: "clear")
                }
            }
            .help("Clear saved quicktask")
        }

        ToolbarItem {
            Button {
                getConfigAndExecute()
            } label: {
                Image(systemName: "play.fill")
                    .foregroundColor(Color(.blue))
            }
            .help("Synchronize (⌘R)")
            .disabled(selectedrsynccommand == .not_selected)
        }

        ToolbarItem {
            Button {
                abort()
            } label: {
                Image(systemName: "stop.fill")
            }
            .help("Abort (⌘K)")
        }
    }

    func resetForm() {
        selectedrsynccommand = .synchronize
        trailingslashoptions = .add
        dryrun = true
        catalogorfile = true
        localcatalog = ""
        remotecatalog = ""
        remoteuser = ""
        remoteserver = ""
        selectedhomecatalog = nil
        selectedAttachedVolume = nil
        selectedAttachedVolumeCatalogs = nil
    }

    func getConfigAndExecute() {
        let getdata = AppendTask(selectedrsynccommand.rawValue,
                                 localcatalog,
                                 remotecatalog,
                                 trailingslashoptions,
                                 remoteuser,
                                 remoteserver,
                                 "")

        guard selectedrsynccommand != .not_selected else { return }

        if let config = VerifyConfiguration().verify(getdata) {
            do {
                let ok = try validateInput(config)
                if ok {
                    execute(config: config, dryrun: dryrun)
                }
            } catch let err {
                let error = err
                propagateError(error: error)
            }
        }
    }

    func execute(config: SynchronizeConfiguration, dryrun: Bool) {
        let arguments = ArgumentsSynchronize(config: config).argumentsSynchronize(dryRun: dryrun, forDisplay: false)
        // Start progressview
        showprogressview = true

        let handlers = CreateHandlers().createHandlers(
            fileHandler: fileHandler,
            processTermination: processTermination
        )

        // Must check valid rsync exists
        guard SharedReference.shared.norsync == false else { return }
        guard config.task != SharedReference.shared.halted else { return }

        let process = RsyncProcess(arguments: arguments,
                                   hiddenID: config.hiddenID,
                                   handlers: handlers,
                                   useFileHandler: true)
        do {
            try process.executeProcess()
        } catch let err {
            let error = err
            SharedReference.shared.errorobject?.alert(error: error)
        }
    }

    func abort() {
        InterruptProcess()
    }

    func processTermination(_ stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        showprogressview = false
        if dryrun {
            max = Double(stringoutputfromrsync?.count ?? 0)
        }
        Task {
            rsyncoutput.output = await ActorCreateOutputforView().createOutputForView(stringoutputfromrsync)
            completed = true
        }
    }

    func fileHandler(count: Int) {
        progress = Double(count)
    }

    func propagateError(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }

    private func validateInput(_ config: SynchronizeConfiguration) throws -> Bool {
        if config.localCatalog.isEmpty {
            throw ValidateInputQuicktask.localcatalog
        }
        if config.offsiteCatalog.isEmpty {
            throw ValidateInputQuicktask.remotecatalog
        }
        if config.offsiteUsername.isEmpty {
            throw ValidateInputQuicktask.offsiteusername
        }
        if config.offsiteServer.isEmpty {
            throw ValidateInputQuicktask.offsiteserver
        }
        return true
    }
}
