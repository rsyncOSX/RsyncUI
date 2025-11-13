//
//  RestoreTableView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/11/2023.
//
// swiftlint:disable line_length

import OSLog
import RsyncProcess
import SwiftUI

struct RestoreTableView: View {
    @State var restore = ObservableRestore()
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var gettingfilelist: Bool = false
    @State private var focusaborttask: Bool = false
    // Restore snapshot
    @State var snapshotdata = ObservableSnapshotData()
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
                                        getsnapshotlogsandcatalogs()
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
                                              restore.restorefilelist.count == 0
                                    {
                                        ContentUnavailableView.search
                                    }
                                }

                            Spacer()
                        }
                    }

                    if gettingfilelist { ProgressView() }
                    if restore.restorefilesinprogress { ProgressView() }

                    if restore.selectedconfig?.offsiteServer.isEmpty == true {
                        DismissafterMessageView(dismissafter: 2, mytext: NSLocalizedString("Use macOS Finder to restore files from attached discs.", comment: ""))
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
                        getlistoffilesforrestore()
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
               restore.restorefilelist.count == 0
            {
                Button {
                    getlistoffilesforrestore()
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
            if restore.selectedconfig?.task != SharedReference.shared.syncremote, restore.selectedconfig?.offsiteServer.isEmpty == false,
               restore.restorefilelist.count > 0,
               restore.filestorestore.isEmpty == false
            {
                Button {
                    executerestore()
                } label: {
                    Image(systemName: "play.fill")
                        .foregroundColor(Color(.blue))
                }
                .help("Restore files")
            }
        }

        ToolbarItem {
            if restore.selectedconfig?.task != SharedReference.shared.syncremote, restore.selectedconfig?.offsiteServer.isEmpty == false,
               restore.restorefilelist.count > 0,
               restore.filestorestore.isEmpty == false
            {
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
        EditValueErrorScheme(500, NSLocalizedString("Path for restore", comment: ""), $restore.pathforrestore,
                             restore.verifypathforrestore(restore.pathforrestore))
            .foregroundColor(restore.verifypathforrestore(restore.pathforrestore) ? Color.white : Color.red)
            .onAppear {
                if let pathforrestore = SharedReference.shared.pathforrestore {
                    restore.pathforrestore = pathforrestore
                }
            }
            .onChange(of: restore.pathforrestore) {
                guard restore.verifypathforrestore(restore.pathforrestore) else {
                    return
                }
                if restore.pathforrestore.hasSuffix("/") == false {
                    restore.pathforrestore.append("/")
                }
                SharedReference.shared.pathforrestore = restore.pathforrestore
            }
    }

    var setfilestorestore: some View {
        EditValueScheme(500, NSLocalizedString("Select files to restore or \"./.\" for full restore", comment: ""),
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
    func getlistoffilesforrestore() {
        if let config = restore.selectedconfig {
            guard config.task != SharedReference.shared.syncremote else { return }
            guard config.offsiteServer.isEmpty == false else { return }
            gettingfilelist = true
            getfilelist()
        }
    }

    func abort() {
        InterruptProcess()
    }

    func processtermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        gettingfilelist = false
        restore.restorefilelist.removeAll()
        Task {
            restore.restorefilelist = await ActorCreateOutputforView().createoutputforrestore(stringoutputfromrsync)
        }
    }

    func getfilelist() {
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
            guard arguments?.isEmpty == false else { return }

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
                environment: MyEnvironment()?.environment,
            printlines: RsyncOutputCapture.shared.makePrintLinesClosure()
            )

            let process = RsyncProcess(arguments: arguments,
                                       handlers: handlers,
                                       filehandler: false)
            do {
                try process.executeProcess()
            } catch let e {
                let error = e
                SharedReference.shared.errorobject?.alert(error: error)
            }
        }
    }

    func executerestore() {
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
                restore.executerestore()
            } else {
                restore.executerestore()
            }
        }
    }

    func getsnapshotlogsandcatalogs() {
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

// swiftlint:enable line_length
