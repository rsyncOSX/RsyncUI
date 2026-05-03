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
    @State private var snapshotfolder: String = ""
    @State private var snapshotFolderID: SnapshotFolder.ID?
    // Filterstring
    @State private var filterstring: String = ""
    @State private var filterTask: Task<Void, Never>?
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
                               configurations: configurations,
                               getSnapshotLogsAndCatalogs: getSnapshotLogsAndCatalogs)

            Spacer()

            if focusaborttask { labelaborttask }

            RestoreControlsView(restore: $restore)
                .focusedSceneValue(\.aborttask, $focusaborttask)
                .searchable(text: $filterstring)
                .onChange(of: filterstring) {
                    filterTask?.cancel()
                    filterTask = Task {
                        try? await Task.sleep(seconds: 1)
                        guard Task.isCancelled == false else { return }
                        if filterstring.isEmpty == false {
                            restore.restorefilelist = restore.restorefilelist.filter { $0.record.contains(filterstring) }
                        } else {
                            getListOfFilesForRestore()
                        }
                    }
                }
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
        Picker("", selection: $snapshotFolderID) {
            Text("Select a folder")
                .tag(nil as SnapshotFolder.ID?)
            ForEach(snapshotdata.snapshotfolders) { catalog in
                Text(catalog.folder)
                    .tag(catalog.id)
            }
        }
        .frame(width: 150)
        .tint(.blue)
        .onChange(of: snapshotFolderID) {
            if let index = snapshotdata.snapshotfolders.firstIndex(where: { $0.id == snapshotFolderID }) {
                snapshotfolder = snapshotdata.snapshotfolders[index].folder
            } else {
                restore.restorefilelist.removeAll()
            }
        }
        .onChange(of: profile) {
            snapshotdata.snapshotfolders.removeAll()
        }
        .onAppear {
            snapshotdata.snapshotfolders.removeAll()
        }
        .onChange(of: snapshotfolder) {
            restore.restorefilelist.removeAll()
            restore.filestorestore = ""
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

    func processTermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        Task {
            gettingfilelist = false
            restore.restorefilelist.removeAll()
            let list = await CreateOutputforView().createoutputforrestore(stringoutputfromrsync)
            restore.restorefilelist = list
        }
    }

    func getFileList() {
        if let config = restore.selectedconfig {
            var arguments: [String]?
            let snapshot: Bool = (config.snapshotnum != nil) ? true : false
            if snapshot, snapshotfolder.isEmpty == false {
                // Snapshot and other than last snapshot is selected
                var tempconfig = config
                if let snapshotnum = Int(snapshotfolder.dropFirst(2)) {
                    // Must increase the snapshotnum by 1 because the
                    // config stores next to use snapshotnum and the comnpute
                    // arguments for restore reduce the snapshotnum by 1
                    tempconfig.snapshotnum = snapshotnum + 1
                    arguments = ArgumentsRemoteFileList(config: tempconfig).remotefilelistarguments()
                }
            } else {
                arguments = ArgumentsRemoteFileList(config: config).remotefilelistarguments()
            }
            guard let arguments else { return }

            streamingHandlers = CreateStreamingHandlers().createHandlersWithCleanup(
                fileHandler: { _ in },
                processTermination: { output, hiddenID in
                    processTermination(stringoutputfromrsync: output, hiddenID: hiddenID)
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
        if let config = restore.selectedconfig, restore.filestorestore.isEmpty == false {
            let snapshot: Bool = (config.snapshotnum != nil) ? true : false
            if snapshot, snapshotfolder.isEmpty == false {
                var tempconfig = config
                if let snapshotnum = Int(snapshotfolder.dropFirst(2)) {
                    // Must increase the snapshotnum by 1 because the
                    // config stores next to use snapshotnum and the comnpute
                    // arguments for restore reduce the snapshotnum by 1
                    tempconfig.snapshotnum = snapshotnum + 1
                }
                restore.selectedconfig = tempconfig
                restore.executeRestore()
            } else {
                restore.executeRestore()
            }
        }
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
