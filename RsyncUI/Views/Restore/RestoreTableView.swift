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
    // Restore snapshot
    @State var snapshotdata = ObservableSnapshotData()
    // Streaming strong references
    @State private var streamingHandlers: RsyncProcessStreaming.ProcessHandlers?
    @State private var activeStreamingProcess: RsyncProcessStreaming.RsyncProcess?
    @State private var snapshotfolder: String = ""
    @State private var snapshotFolderID: SnapshotFolder.ID?
    // Filterstring
    @State private var filterstring: String = ""
    @Binding var profile: String?

    let configurations: [SynchronizeConfiguration]

    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    HStack {
                        ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                                    configurations: configurations)
                            .onChange(of: selecteduuids) {
                                if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                                    restore.selectedconfig = configurations[index]
                                    if configurations[index].task == SharedReference.shared.snapshot {
                                        getSnapshotLogsAndCatalogs()
                                    }
                                    restore.restorefilelist.removeAll()
                                } else {
                                    restore.selectedconfig = nil
                                    restore.filestorestore = ""
                                    restore.restorefilelist.removeAll()
                                    snapshotdata.snapshotfolders.removeAll()
                                    filterstring = ""
                                }
                            }
                            .overlay {
                                if configurations.count == 0 {
                                    ContentUnavailableView {
                                        Label("No tasks yet", systemImage: "doc.richtext.fill")
                                    } description: {
                                        Text("And nothing to restore")
                                    }
                                }
                            }

                        VStack(alignment: .leading) {
                            RestoreFilesTableView(filestorestore: $restore.filestorestore,
                                                  datalist: restore.restorefilelist)
                                .onChange(of: profile) {
                                    restore.restorefilelist.removeAll()
                                }
                                .overlay { if filterstring.count > 0,
                                              restore.restorefilelist.count == 0 {
                                        ContentUnavailableView.search
                                    }
                                }

                            Spacer()
                        }
                    }

                    if gettingfilelist { ProgressView() }
                    if restore.restorefilesinprogress { SynchronizeProgressView(max: restore.max, progress: restore.progress,
                                                                                statusText: "Restoring...") }

                    if restore.selectedconfig?.offsiteServer.isEmpty == true {
                        DismissafterMessageView(dismissafter: 2, mytext: "Use macOS Finder to restore files from attached discs.")
                    }
                }

                Spacer()

                if focusaborttask { labelaborttask }
            }

            HStack {
                VStack(alignment: .leading) {
                    setfilestorestore

                    setpathforrestore
                }

                Spacer()

                Toggle("--dry-run", isOn: $restore.dryrun)
                    .toggleStyle(.switch)
                    .onTapGesture {
                        withAnimation(Animation.easeInOut(duration: true ? 0.35 : 0)) {
                            restore.dryrun.toggle()
                        }
                    }
            }
            .focusedSceneValue(\.aborttask, $focusaborttask)
            .searchable(text: $filterstring)
            .onChange(of: filterstring) {
                Task {
                    try await Task.sleep(seconds: 1)
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
                    Image(systemName: "square.and.arrow.down.fill")
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
                    Image(systemName: "play.fill")
                        .foregroundColor(Color(.blue))
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
                    Image(systemName: "doc.plaintext")
                }
                .help("Output from rsync")
            }
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

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear {
                focusaborttask = false
                abort()
            }
    }

    var setpathforrestore: some View {
        EditValueErrorScheme(500, "Path for restore", $restore.pathforrestore,
                             restore.verifyPathForRestore(restore.pathforrestore))
            .foregroundColor(restore.verifyPathForRestore(restore.pathforrestore) ? Color.white : Color.red)
            .onAppear {
                if let pathforrestore = SharedReference.shared.pathforrestore {
                    restore.pathforrestore = pathforrestore
                }
            }
            .onChange(of: restore.pathforrestore) {
                guard restore.verifyPathForRestore(restore.pathforrestore) else {
                    return
                }
                if restore.pathforrestore.hasSuffix("/") == false {
                    restore.pathforrestore.append("/")
                }
                SharedReference.shared.pathforrestore = restore.pathforrestore
            }
    }

    var setfilestorestore: some View {
        EditValueScheme(500, "Select files to restore or \"./.\" for full restore",
                        $restore.filestorestore)
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
        .accentColor(.blue)
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
        DispatchQueue.main.async {
            gettingfilelist = false
            restore.restorefilelist.removeAll()
        }
        Task.detached { [stringoutputfromrsync] in
            let list = await ActorCreateOutputforView().createoutputforrestore(stringoutputfromrsync)
            await MainActor.run { restore.restorefilelist = list }
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
            
            streamingHandlers = CreateStreamingHandlers().createHandlers(
                fileHandler: { _ in },
                processTermination: { output, hiddenID in
                    processTermination(stringoutputfromrsync: output, hiddenID: hiddenID)
                }
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
