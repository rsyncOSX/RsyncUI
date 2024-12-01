//
//  RestoreTableView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/11/2023.
//
// swiftlint:disable line_length

import SwiftUI

struct RestoreTableView: View {
    @State var restore = ObservableRestore()
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var gettingfilelist: Bool = false
    @State private var focusaborttask: Bool = false
    // Restore snapshot
    @State var snapshotdata = SnapshotData()
    @State private var snapshotcatalog: String = ""
    // Filterstring
    @State private var filterstring: String = ""
    @Binding var profile: String?

    let configurations: [SynchronizeConfiguration]

    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    HStack {
                        ListofTasksLightView(selecteduuids: $selecteduuids,
                                             profile: profile,
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
                                    snapshotdata.catalogsanddates.removeAll()
                                    filterstring = ""
                                }
                            }

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
            .toolbar(content: {
                ToolbarItem {
                    if restore.selectedconfig?.task != SharedReference.shared.syncremote, restore.selectedconfig?.offsiteServer.isEmpty == false,
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
                        snapshotcatalogpicker
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
                            Image(systemName: "checkmark.circle.fill")
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
            })
        }
        .navigationTitle("Restore files")
        .navigationDestination(isPresented: $restore.presentrestorelist) {
            OutputRsyncView(output: restore.restorefilelist)
        }
        .padding()
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }

    var setpathforrestore: some View {
        EditValue(500, NSLocalizedString("Path for restore", comment: ""), $restore.pathforrestore)
            .onAppear(perform: {
                if let pathforrestore = SharedReference.shared.pathforrestore {
                    restore.pathforrestore = pathforrestore
                }
            })
            .onChange(of: restore.pathforrestore) {
                restore.validatepathforrestore(restore.pathforrestore)
            }
    }

    var setfilestorestore: some View {
        EditValue(500, NSLocalizedString("Select files to restore or \"./.\" for full restore", comment: ""),
                  $restore.filestorestore)
    }

    var snapshotcatalogpicker: some View {
        Picker("", selection: $snapshotcatalog) {
            Text("")
                .tag("")
            ForEach(snapshotdata.catalogsanddates) { catalog in
                Text(catalog.catalog)
                    .tag(catalog.catalog)
            }
        }
        .frame(width: 150)
        .accentColor(.blue)
        .onChange(of: snapshotdata.catalogsanddates) {
            guard snapshotdata.catalogsanddates.count > 0 else { return }
            snapshotcatalog = snapshotdata.catalogsanddates[0].catalog
        }
        .onChange(of: profile) {
            snapshotdata.catalogsanddates.removeAll()
        }
        .onAppear {
            snapshotdata.catalogsanddates.removeAll()
        }
        .onChange(of: snapshotcatalog) {
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
        if let stringoutputfromrsync {
            // let trimmeddata = TrimOutputForRestore(stringoutputfromrsync).trimmeddata?.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }
            if let trimmeddata = TrimOutputForRestore(stringoutputfromrsync).trimmeddata {
                restore.restorefilelist = trimmeddata.map { filename in
                    RsyncOutputData(record: filename)
                }
            }
        }
    }

    func getfilelist() {
        if let config = restore.selectedconfig {
            var arguments: [String]?
            let snapshot: Bool = (config.snapshotnum != nil) ? true : false
            if snapshot, snapshotcatalog.isEmpty == false {
                // Snapshot and other than last snapshot is selected
                var tempconfig = config
                if let snapshotnum = Int(snapshotcatalog.dropFirst(2)) {
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
            let command = ProcessRsync(arguments: arguments,
                                       processtermination: processtermination)
            command.executeProcess()
        }
    }

    func executerestore() {
        if let config = restore.selectedconfig, restore.filestorestore.isEmpty == false {
            let snapshot: Bool = (config.snapshotnum != nil) ? true : false
            if snapshot, snapshotcatalog.isEmpty == false {
                var tempconfig = config
                if let snapshotnum = Int(snapshotcatalog.dropFirst(2)) {
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
