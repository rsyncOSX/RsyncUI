//
//  RestoreTableView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/11/2023.
//
// swiftlint:disable line_length

import Combine
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
    @State var publisher = PassthroughSubject<String, Never>()
    @State private var showindebounce: Bool = false

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
                                    restore.datalist.removeAll()
                                } else {
                                    restore.selectedconfig = nil
                                    restore.filestorestore = ""
                                    restore.datalist.removeAll()
                                    snapshotdata.catalogsanddates.removeAll()
                                    filterstring = ""
                                    restore.rsyncdata = nil
                                }
                            }

                        RestoreFilesTableView(filestorestore: $restore.filestorestore,
                                              datalist: restore.datalist)
                            .onChange(of: profile) {
                                restore.datalist.removeAll()
                            }
                            .overlay { if filterstring.count > 0,
                                          restore.rsyncdata?.count ?? 0 > 0,
                                          restore.datalist.count == 0
                                {
                                    ContentUnavailableView.search
                                }
                            }
                    }

                    if gettingfilelist { ProgressView() }
                    if restore.restorefilesinprogress { ProgressView() }

                    if restore.selectedconfig?.offsiteServer.isEmpty == true {
                        MessageView(dismissafter: 2, mytext: NSLocalizedString("Use macOS Finder to restore files from attached discs.", comment: ""), width: 450)
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

                if showindebounce { indebounce }

                Spacer()

                Toggle("--dry-run", isOn: $restore.dryrun)
                    .toggleStyle(.switch)
            }
            .focusedSceneValue(\.aborttask, $focusaborttask)
            .searchable(text: $filterstring)
            .onChange(of: filterstring) {
                showindebounce = true
                publisher.send(filterstring)
            }
            .onReceive(
                publisher.debounce(
                    for: .seconds(1),
                    scheduler: DispatchQueue.main
                )
            ) { filter in
                showindebounce = false
                if restore.rsyncdata?.count ?? 0 > 0, filter.isEmpty == false {
                    filterrestorefilelist()
                } else {
                    restore.datalist = restore.rsyncdata?.map { filename in
                        RestoreFileRecord(filename: filename)
                    } ?? []
                }
            }
            .toolbar(content: {
                ToolbarItem {
                    if restore.selectedconfig?.task != SharedReference.shared.syncremote, restore.selectedconfig?.offsiteServer.isEmpty == false {
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
                    Button {
                        executerestore()
                    } label: {
                        Image(systemName: "return")
                            .foregroundColor(Color(.blue))
                    }
                    .help("Restore files")
                }

                ToolbarItem {
                    Button {
                        guard SharedReference.shared.process == nil else { return }
                        guard restore.selectedconfig != nil else { return }
                        restore.presentsheetrsync = true
                    } label: {
                        Image(systemName: "doc.plaintext")
                    }
                    .help("Output from rsync")
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
        .navigationDestination(isPresented: $restore.presentsheetrsync) {
            OutputRsyncView(output: restore.rsyncdata ?? [])
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
            restore.datalist.removeAll()
            restore.filestorestore = ""
        }
    }

    var indebounce: some View {
        ProgressView()
            .controlSize(.small)
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
        _ = InterruptProcess()
    }

    func processtermination(data: [String]?, hiddenID _: Int?) {
        gettingfilelist = false
        restore.rsyncdata = TrimOutputForRestore(data ?? []).trimmeddata.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }
        restore.datalist = restore.rsyncdata?.map { filename in
            RestoreFileRecord(filename: filename)
        } ?? []
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
            let command = RsyncProcessNOFilehandler(arguments: arguments,
                                                    processtermination: processtermination)
            command.executeProcess()
        }
    }

    func executerestore() {
        if let config = restore.selectedconfig {
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
            _ = SnapshotRemoteCatalogs(
                config: config,
                snapshotdata: snapshotdata
            )
        }
    }

    func filterrestorefilelist() {
        if let data = restore.rsyncdata?.filter({ $0.contains(filterstring) }) {
            restore.datalist = data.map { filename in
                RestoreFileRecord(filename: filename)
            }
        }
    }
}

struct RestoreFileRecord: Identifiable {
    let id = UUID()
    var filename: String
}

// swiftlint:enable line_length
