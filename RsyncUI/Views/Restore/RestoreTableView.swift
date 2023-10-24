//
//  RestoreTableView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 05/06/2023.
//

import SwiftUI

struct RestoreTableView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @State var restore = ObservableRestore()
    @State private var selecteduuids = Set<Configuration.ID>()
    @State private var gettingfilelist: Bool = false
    @State private var focusaborttask: Bool = false
    // Restore snapshot
    @State var snapshotdata = SnapshotData()
    @State private var snapshotcatalog: String = ""
    // Filterstring
    @State private var filterstring: String = ""

    var body: some View {
        VStack {
            ZStack {
                HStack {
                    ListofTasksLightView(selecteduuids: $selecteduuids)
                        .onChange(of: selecteduuids) {
                            restore.filestorestore = ""
                            restore.datalist = []
                            let selected = rsyncUIdata.configurations?.filter { config in
                                selecteduuids.contains(config.id)
                            }
                            if (selected?.count ?? 0) == 1 {
                                if let config = selected {
                                    restore.selectedconfig = config[0]
                                    if config[0].task == SharedReference.shared.snapshot {
                                        getsnapshotlogsandcatalogs()
                                    }
                                }
                            } else {
                                restore.selectedconfig = nil
                                restore.filestorestore = ""
                                restore.datalist = []
                                snapshotdata.catalogsanddates.removeAll()
                            }
                        }

                    RestoreFilesTableView(filestorestore: $restore.filestorestore,
                                          datalist: restore.datalist)
                        .onChange(of: rsyncUIdata.profile) {
                            restore.datalist.removeAll()
                        }
                        .onChange(of: filterstring) {
                            Task {
                                if restore.rsyncdata?.count ?? 0 > 0 {
                                    await filterrestorefilelist()
                                }
                            }
                        }
                        .overlay {
                            if filterstring.count > 0,
                               restore.rsyncdata?.count ?? 0 > 0,
                               restore.datalist.count == 0
                            {
                                ContentUnavailableView.search
                            }
                        }
                }

                if gettingfilelist { AlertToast(displayMode: .alert, type: .loading) }
                if restore.restorefilesinprogress { AlertToast(displayMode: .alert, type: .loading) }
            }

            Spacer()

            ZStack {
                if focusaborttask { labelaborttask }
            }
        }

        HStack {
            Spacer()

            VStack(alignment: .leading) {
                setfilestorestore

                setpathforrestore
            }

            Spacer()

            VStack(alignment: .leading) {
                Toggle("--dry-run", isOn: $restore.dryrun)
                    .toggleStyle(.switch)
            }

            Button("Files") {
                Task {
                    if let config = restore.selectedconfig {
                        guard config.task != SharedReference.shared.syncremote else { return }
                        gettingfilelist = true
                        await getfilelist()
                    }
                }
            }
            .buttonStyle(ColorfulButtonStyle())

            Button("Restore") {
                Task {
                    await restore()
                }
            }
            .buttonStyle(ColorfulButtonStyle())
        }
        .sheet(isPresented: $restore.presentsheetrsync) { viewoutput }
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .searchable(text: $filterstring)
        .toolbar(content: {
            ToolbarItem {
                if restore.selectedconfig?.task == SharedReference.shared.snapshot {
                    snapshotcatalogpicker
                }
            }

            ToolbarItem {
                Button {
                    guard SharedReference.shared.process == nil else { return }
                    guard restore.selectedconfig != nil else { return }
                    restore.presentsheetrsync = true
                } label: {
                    Image(systemName: "doc.plaintext")
                }
                .tooltip("View output")
            }

            ToolbarItem {
                Button {
                    abort()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .tooltip("Abort (⌘K)")
            }
        })
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

    var numberoffiles: some View {
        HStack {
            Text(NSLocalizedString("Number of files", comment: "") + ": ")
            Text(NumberFormatter.localizedString(from: NSNumber(value: restore.numberoffiles),
                                                 number: NumberFormatter.Style.decimal))
                .foregroundColor(Color.blue)

            Spacer()
        }
        .frame(width: 300)
    }

    // Output from rsync
    var viewoutput: some View {
        OutputRsyncView(output: restore.rsyncdata ?? [])
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
        .onChange(of: rsyncUIdata.profile) {
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
}

extension RestoreTableView {
    func abort() {
        _ = InterruptProcess()
    }

    func processtermination(data: [String]?) {
        gettingfilelist = false
        restore.rsyncdata = data
        let data = TrimOne(data ?? []).trimmeddata.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }
        restore.datalist = data.map { filename in
            RestoreFileRecord(filename: filename)
        }
    }

    @MainActor
    func getfilelist() async {
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
                    arguments = RestorefilesArguments(task: .rsyncfilelistings,
                                                      config: tempconfig,
                                                      remoteFile: nil,
                                                      localCatalog: nil,
                                                      drynrun: nil,
                                                      snapshot: snapshot).getArguments()
                }
            } else {
                arguments = RestorefilesArguments(task: .rsyncfilelistings,
                                                  config: config,
                                                  remoteFile: nil,
                                                  localCatalog: nil,
                                                  drynrun: nil,
                                                  snapshot: snapshot).getArguments()
            }
            guard arguments?.isEmpty == false else { return }
            let command = RsyncAsync(arguments: arguments,
                                     processtermination: processtermination)
            await command.executeProcess()
        }
    }

    @MainActor
    func restore() async {
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
                await restore.restore()
            } else {
                await restore.restore()
            }
        }
    }

    func getsnapshotlogsandcatalogs() {
        guard SharedReference.shared.process == nil else { return }
        if let config = restore.selectedconfig {
            guard config.task == SharedReference.shared.snapshot else { return }
            _ = Snapshotcatalogs(
                config: config,
                snapshotdata: snapshotdata
            )
        }
    }

    func filterrestorefilelist() async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        let data = TrimOne(restore.rsyncdata ?? []).trimmeddata.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }
        restore.datalist = data.map { filename in
            RestoreFileRecord(filename: filename)
        }
    }
}

struct RestoreFileRecord: Identifiable {
    let id = UUID()
    var filename: String
}
