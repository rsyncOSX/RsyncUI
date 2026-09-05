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
                Label("Clear saved quicktask", systemImage: "clear")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(localcatalog.isEmpty == false ? Color(.red) : .primary)
            }
            .help("Clear saved quicktask")
        }

        ToolbarItem {
            Button {
                getConfigAndExecute()
            } label: {
                Label("Synchronize", systemImage: "play.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(Color(.blue))
            }
            .help("Synchronize (⌘R)")
            .disabled(selectedrsynccommand == .notSelected)
        }

        ToolbarItem {
            Button {
                abort()
            } label: {
                Label("Abort", systemImage: "stop.fill")
                    .labelStyle(.iconOnly)
            }
            .help("Abort (⌘K)")
        }
    }

    func resetForm() {
        selectedrsynccommand = .synchronize
        trailingslashoptions = true
        dryrun = true
        catalogorfile = true
        localcatalog = ""
        remotecatalog = ""
        remoteuser = ""
        remoteserver = ""
        selectedhomecatalog = nil
        selectedAttachedVolumeCatalogs = nil
    }

    func getConfigAndExecute() {
        guard selectedrsynccommand != .notSelected else { return }

        let sourceCatalog = QuickTaskSourcePath.applyingTrailingSlash(
            to: localcatalog,
            enabled: trailingslashoptions
        )
        let getdata = NewTask(selectedrsynccommand.rawValue,
                              sourceCatalog,
                              remotecatalog,
                              remoteuser,
                              remoteserver,
                              "")

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
        guard showprogressview == false else { return }
        guard SharedReference.shared.norsync == false else {
            propagateError(error: Validatedrsync.norsync)
            return
        }
        guard config.task != SharedReference.shared.halted else { return }
        guard let arguments = ArgumentsSynchronize(config: config)
            .argumentsSynchronize(dryRun: dryrun, forDisplay: false) else { return }

        let handlers = CreateStreamingHandlers().createHandlers(
            fileHandler: fileHandler,
            processTermination: { output, exitCode in
                Task { @MainActor in
                    processTermination(output, exitCode)
                }
            }
        )

        // Use streaming process with readability handlers; do not use file handler
        let streamingProcess = RsyncProcessStreaming.RsyncProcess(
            arguments: arguments,
            hiddenID: config.hiddenID,
            handlers: handlers,
            useFileHandler: true
        )
        streamingHandlers = handlers
        activeStreamingProcess = streamingProcess
        showprogressview = true
        progress = 0
        completed = false
        do {
            try streamingProcess.executeProcess()
        } catch let err {
            showprogressview = false
            activeStreamingProcess = nil
            streamingHandlers = nil
            propagateError(error: err)
        }
    }

    func abort() {
        InterruptProcess()
    }

    @MainActor
    func processTermination(_ stringoutputfromrsync: [String]?, _: Int?) {
        showprogressview = false
        if dryrun {
            max = Double(stringoutputfromrsync?.count ?? 0)
        }

        rsyncoutput.output = CreateOutputforView().createOutputForView(stringoutputfromrsync)
        completed = true
        // Release process and handler references on completion
        activeStreamingProcess = nil
        streamingHandlers = nil
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

enum QuickTaskSourcePath {
    static func applyingTrailingSlash(to sourceCatalog: String, enabled: Bool) -> String {
        guard sourceCatalog.isEmpty == false else { return sourceCatalog }

        if enabled {
            return sourceCatalog.hasSuffix("/") ? sourceCatalog : sourceCatalog.appending("/")
        }

        var sourceCatalog = sourceCatalog
        while sourceCatalog.count > 1, sourceCatalog.hasSuffix("/") {
            sourceCatalog.removeLast()
        }
        return sourceCatalog
    }
}
