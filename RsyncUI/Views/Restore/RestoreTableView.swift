//
//  RestoreTableView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/11/2023.
//

import OSLog
import RsyncProcessStreaming
import SwiftUI

struct RestoreTableView: View {
    @State var restore = ObservableRestore()
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var gettingfilelist: Bool = false
    @State private var focusaborttask: Bool = false
    /// Restore snapshot
    @State var snapshotdata = ObservableSnapshotData()
    // Streaming strong references
    @State private var streamingHandlers: RsyncProcessStreaming.ProcessHandlers?
    @State private var activeStreamingProcess: RsyncProcessStreaming.RsyncProcess?
    // Filterstring
    @State private var filterstring: String = ""
    @Binding var profile: String?

    let configurations: [SynchronizeConfiguration]

    var body: some View {
        NavigationStack {
            RestoreContentView(restore: $restore,
                               selecteduuids: $selecteduuids,
                               snapshotdata: $snapshotdata,
                               filterstring: $filterstring,
                               gettingfilelist: $gettingfilelist,
                               profile: $profile,
                               configurations: configurations)
                .onChange(of: restore.selectedconfig?.id) {
                    snapshotdata = ObservableSnapshotData()
                    filterstring = ""
                    getSnapshotLogsAndCatalogs()
                }
                .onChange(of: profile) {
                    selecteduuids.removeAll()
                    restore.selectedconfig = nil
                    snapshotdata = ObservableSnapshotData()
                    filterstring = ""
                }

            Spacer()

            if focusaborttask {
                labelaborttask
            }

            RestoreControlsView(restore: $restore)
                .focusedSceneValue(\.aborttask, $focusaborttask)
                .searchable(text: $filterstring)
                .toolbar { restoretoolbarcontent }
        }
        .navigationTitle("Restore files")
        .navigationDestination(isPresented: $restore.presentrestorelist) {
            OutputRsyncView(output: restore.restorefilelist)
        }
        .padding()
    }

    @ToolbarContentBuilder
    private var restoretoolbarcontent: some ToolbarContent {
        ToolbarItem {
            if restore.selectedconfig?.task != SharedReference.shared.syncremote,
               restore.selectedconfig?.task != SharedReference.shared.halted,
               restore.selectedconfig?.offsiteServer.isEmpty == false,
               restore.restorefilelist.count == 0 {
                Button {
                    getListOfFilesForRestore()
                } label: {
                    Label("Get list of files", systemImage: "square.and.arrow.down.fill")
                        .labelStyle(.iconOnly)
                }
                .help("Get list of files for restore")
            }
        }

        ToolbarItem {
            if restore.selectedconfig?.task == SharedReference.shared.snapshot {
                snapshotfolderpicker
            }
        }

        ToolbarItem {
            if restore.selectedconfig?.task != SharedReference.shared.syncremote,
               restore.selectedconfig?.offsiteServer.isEmpty == false,
               restore.restorefilelist.count > 0,
               restore.filestorestore.isEmpty == false {
                Button {
                    executeRestore()
                } label: {
                    Label("Restore files", systemImage: "play.fill")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(Color(.blue))
                }
                .help("Restore files")
                .disabled(!restore.canRestore || gettingfilelist || SharedReference.shared.process != nil)
            }
        }

        ToolbarItem {
            if restore.selectedconfig?.task != SharedReference.shared.syncremote,
               restore.selectedconfig?.offsiteServer.isEmpty == false,
               restore.restorefilelist.count > 0,
               restore.filestorestore.isEmpty == false {
                Button {
                    guard SharedReference.shared.process == nil else { return }
                    guard restore.selectedconfig != nil else { return }
                    restore.presentrestorelist = true
                } label: {
                    Label("Output from rsync", systemImage: "doc.plaintext")
                        .labelStyle(.iconOnly)
                }
                .help("Output from rsync")
            }
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

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear {
                focusaborttask = false
                abort()
            }
    }

    var snapshotfolderpicker: some View {
        Picker("Snapshot", selection: $restore.selectedSnapshot) {
            Text("Latest snapshot")
                .tag(nil as String?)
            ForEach(snapshotdata.snapshotfolders) { catalog in
                Text(catalog.folder)
                    .tag(catalog.folder as String?)
            }
        }
        .frame(width: 180)
        .disabled(gettingfilelist || restore.restorefilesinprogress)
        .onChange(of: snapshotdata.snapshotfolders) {
            if let selected = restore.selectedSnapshot,
               !snapshotdata.snapshotfolders.contains(where: { $0.folder == selected }) {
                restore.selectedSnapshot = nil
            }
        }
    }
}

extension RestoreTableView {
    func getListOfFilesForRestore() {
        if let config = restore.selectedconfig {
            guard config.task != SharedReference.shared.syncremote else { return }
            guard config.offsiteServer.isEmpty == false else { return }
            gettingfilelist = true
            getFileList()
        }
    }

    func abort() {
        InterruptProcess()
    }

    @MainActor
    func processTermination(stringoutputfromrsync: [String]?, configID: UUID, snapshot: String?) async {
        gettingfilelist = false
        let list = await CreateOutputforView().createoutputforrestore(stringoutputfromrsync)
        guard restore.selectedconfig?.id == configID, restore.selectedSnapshot == snapshot else { return }
        restore.restorefilelist = list
    }

    func getFileList() {
        if let config = try? restore.configurationForRestore() {
            let requestedSnapshot = restore.selectedSnapshot
            let arguments = ArgumentsRemoteFileList(config: config).remotefilelistarguments()
            guard let arguments else { return }

            streamingHandlers = CreateStreamingHandlers().createHandlersWithCleanup(
                fileHandler: { _ in },
                processTermination: { output, _ in
                    Task { @MainActor in
                        await processTermination(stringoutputfromrsync: output, configID: config.id, snapshot: requestedSnapshot)
                    }
                },
                cleanup: { activeStreamingProcess = nil; streamingHandlers = nil }
            )

            guard let streamingHandlers else { return }

            let process = RsyncProcessStreaming.RsyncProcess(
                arguments: arguments,
                handlers: streamingHandlers,
                useFileHandler: false
            )
            do {
                try process.executeProcess()
                activeStreamingProcess = process
            } catch let err {
                let error = err
                SharedReference.shared.errorobject?.alert(error: error)
            }
        }
    }

    func executeRestore() {
        restore.executeRestore()
    }

    func getSnapshotLogsAndCatalogs() {
        guard SharedReference.shared.process == nil else { return }
        if let config = restore.selectedconfig {
            guard config.task == SharedReference.shared.snapshot else { return }
            SnapshotRemoteCatalogs(
                config: config,
                snapshotdata: snapshotdata
            )
        }
    }
}
