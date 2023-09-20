//
//  RestoreTableView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 05/06/2023.
//

import SwiftUI

struct RestoreTableView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @StateObject var restore = ObservableRestore()
    @State private var selecteduuids = Set<Configuration.ID>()
    @State private var filestorestore: String = ""

    @State private var showrestorecommand: Bool = false
    @State private var gettingfilelist: Bool = false
    @State private var filterstring: String = ""
    @State private var nosearcstringalert: Bool = false

    @State private var focusaborttask: Bool = false

    // Restore snapshot
    @StateObject var snapshotdata = SnapshotData()
    @State private var snapshotcatalog: String = ""

    var body: some View {
        VStack {
            ZStack {
                HStack {
                    ListofTasksLightView(selecteduuids: $selecteduuids)
                        .onChange(of: selecteduuids) { _ in
                            restore.filestorestore = ""
                            restore.commandstring = ""
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
                                restore.commandstring = ""
                                restore.datalist = []
                                snapshotdata.catalogsanddates.removeAll()
                            }
                        }

                    RestoreFilesTableView(filestorestore: $filestorestore,
                                          datalist: restore.datalist)
                        .onChange(of: filestorestore) { value in
                            restore.filestorestore = value
                            restore.updatecommandstring()
                        }
                }

                if nosearcstringalert { nosearchstring }
                if gettingfilelist { AlertToast(displayMode: .alert, type: .loading) }
                if restore.restorefilesinprogress { AlertToast(displayMode: .alert, type: .loading) }
            }

            Spacer()

            ZStack {
                if showrestorecommand { showcommand }
                if focusaborttask { labelaborttask }
            }
        }

        HStack {
            Spacer()

            VStack(alignment: .leading) {
                setfilter

                setfilestorestore

                setpathforrestore
            }

            Spacer()

            VStack(alignment: .leading) {
                snapshotcatalogpicker

                Toggle("Command", isOn: $showrestorecommand)
                    .toggleStyle(.switch)

                Toggle("--dry-run", isOn: $restore.dryrun)
                    .toggleStyle(.switch)
            }

            Button("Files") {
                Task {
                    guard filterstring.count > 0 ||
                        restore.filestorestore == "./." ||
                        restore.selectedconfig != nil
                    else {
                        nosearcstringalert = true
                        return
                    }
                    if let config = restore.selectedconfig {
                        guard config.task != SharedReference.shared.syncremote else { return }
                        if filterstring == "./." {
                            filterstring = ""
                            restore.filestorestore = "./."
                        }
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
        .toolbar(content: {
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

    var nosearchstring: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text("Either select a task\n or add a search string")
                .font(.title3)
                .foregroundColor(Color.accentColor)
        }
        .frame(width: 220, height: 40, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                nosearcstringalert = false
            }
        }
    }

    var showcommand: some View {
        Text(restore.commandstring)
            .textSelection(.enabled)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity)
    }

    var setpathforrestore: some View {
        EditValue(500, NSLocalizedString("Path for restore", comment: ""), $restore.pathforrestore)
            .onAppear(perform: {
                if let pathforrestore = SharedReference.shared.pathforrestore {
                    restore.pathforrestore = pathforrestore
                }
            })
            .onChange(of: restore.pathforrestore) { _ in
                restore.validatepathforrestore(restore.pathforrestore)
                restore.updatecommandstring()
            }
    }

    var setfilestorestore: some View {
        EditValue(500, NSLocalizedString("Select files to restore or \"./.\" for full restore", comment: ""),
                  $restore.filestorestore)
    }

    var setfilter: some View {
        EditValue(500, NSLocalizedString("Filter to search remote data", comment: ""), $filterstring)
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
        HStack {
            Picker("Snapshot", selection: $snapshotcatalog) {
                if snapshotdata.catalogsanddates.count == 1 {
                    Text("Not snapshot").tag("")
                } else {
                    ForEach(snapshotdata.catalogsanddates) { catalog in
                        Text(catalog.catalog)
                            .tag(catalog.catalog)
                    }
                }
            }
            .frame(width: 150)
            .accentColor(.blue)
        }
    }
}

extension RestoreTableView {
    func abort() {
        _ = InterruptProcess()
    }

    func processtermination(data: [String]?) {
        gettingfilelist = false
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
}

struct RestoreFileRecord: Identifiable {
    let id = UUID()
    var filename: String = ""
}
