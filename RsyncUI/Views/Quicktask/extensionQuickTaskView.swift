import OSLog
import RsyncProcessStreaming
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
                let isValid = try validateInput(config)
                if isValid {
                    executestreaming(config: config, dryrun: dryrun)
                }
            } catch let err {
                let error = err
                propagateError(error: error)
            }
        }
    }

    func executestreaming(config: SynchronizeConfiguration, dryrun: Bool) {
        let arguments = ArgumentsSynchronize(config: config).argumentsSynchronize(dryRun: dryrun, forDisplay: false)

        // Start progressview
        showprogressview = true

        // Create streaming handlers and retain them (with enforced cleanup)
        streamingHandlers = CreateStreamingHandlers().createHandlersWithCleanup(
            fileHandler: fileHandler,
            processTermination: { output, exitCode in processTermination(output, exitCode) },
            cleanup: { activeStreamingProcess = nil; streamingHandlers = nil }
        )

        // Must check valid rsync exists
        guard SharedReference.shared.norsync == false else { return }
        guard config.task != SharedReference.shared.halted else { return }
        guard let streamingHandlers else { return }
        guard let arguments else { return }

        // Use streaming process with readability handlers; do not use file handler
        let streamingProcess = RsyncProcessStreaming.RsyncProcess(
            arguments: arguments,
            hiddenID: config.hiddenID,
            handlers: streamingHandlers,
            useFileHandler: true
        )
        do {
            try streamingProcess.executeProcess()
        } catch let err {
            let error = err
            SharedReference.shared.errorobject?.alert(error: error)
        }
        // Keep strong reference to streaming process while it's running
        activeStreamingProcess = streamingProcess
    }

    func abort() {
        InterruptProcess()
    }

    func processTermination(_ stringoutputfromrsync: [String]?, _: Int?) {
        // Update immediate UI bits on main
        DispatchQueue.main.async { [self] in
            showprogressview = false
            if dryrun {
                max = Double(stringoutputfromrsync?.count ?? 0)
            }
        }
        // Build output off the main thread, then assign on main
        Task.detached(priority: .userInitiated) { [stringoutputfromrsync] in
            let output = await ActorCreateOutputforView().createOutputForView(stringoutputfromrsync)
            await MainActor.run {
                rsyncoutput.output = output
                completed = true
                // Release process and handler references on completion
                activeStreamingProcess = nil
                streamingHandlers = nil
            }
        }
    }

    func fileHandler(count: Int) {
        Task { @MainActor in
            progress = Double(count)
        }
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
