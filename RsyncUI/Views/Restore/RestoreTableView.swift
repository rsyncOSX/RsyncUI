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
    @State private var filestorestore: String = ""

    @State private var showrestorecommand: Bool = false
    @State private var gettingfilelist: Bool = false
    @State private var filterstring: String = ""
    @State private var nosearcstringalert: Bool = false

    @State private var focusaborttask: Bool = false

    var body: some View {
        VStack {
            ZStack {
                HStack {
                    ListofTasksLightView(
                        selecteduuids: $selecteduuids)
                        .onChange(of: selecteduuids) {
                            restore.filestorestore = ""
                            restore.commandstring = ""
                            restore.datalist = []
                            let selected = rsyncUIdata.configurations?.filter { config in
                                selecteduuids.contains(config.id)
                            }
                            if (selected?.count ?? 0) == 1 {
                                if let config = selected {
                                    restore.selectedconfig = config[0]
                                }
                            } else {
                                restore.selectedconfig = nil
                                restore.filestorestore = ""
                                restore.commandstring = ""
                                restore.datalist = []
                            }
                        }

                    RestoreFilesTableView(filestorestore: $filestorestore, datalist: restore.datalist)
                        .onChange(of: filestorestore) {
                            restore.filestorestore = filestorestore
                            restore.updatecommandstring()
                        }
                        .frame(maxWidth: .infinity)
                }

                if nosearcstringalert { nosearchstring }
            }

            Spacer()

            ZStack {
                if showrestorecommand { showcommand }
                if gettingfilelist { AlertToast(displayMode: .alert, type: .loading) }
                if restore.restorefilesinprogress { AlertToast(displayMode: .alert, type: .loading) }
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

            VStack {
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
                        await getfilelist(config)
                    }
                }
            }
            .buttonStyle(ColorfulButtonStyle())

            Button("Restore") {
                Task {
                    if let config = restore.selectedconfig {
                        await restore.restore(config)
                    }
                }
            }
            .buttonStyle(ColorfulButtonStyle())

            Button("Log") {
                guard SharedReference.shared.process == nil else { return }
                guard restore.selectedconfig != nil else { return }
                restore.presentsheetrsync = true
            }
            .buttonStyle(ColorfulButtonStyle())
            .sheet(isPresented: $restore.presentsheetrsync) { viewoutput }
            /*
             Button("Abort") { abort() }
                 .buttonStyle(ColorfulRedButtonStyle())
              */
        }
        .sheet(isPresented: $restore.presentsheetrsync) { viewoutput }
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .toolbar(content: {
            ToolbarItem {
                Button {
                    abort()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .tooltip("Abort (⌘K)")
            }

            ToolbarItem {
                Spacer()
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
            .onChange(of: restore.pathforrestore) {
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
    func getfilelist(_ config: Configuration) async {
        let snapshot: Bool = (config.snapshotnum != nil) ? true : false
        let arguments = RestorefilesArguments(task: .rsyncfilelistings,
                                              config: config,
                                              remoteFile: nil,
                                              localCatalog: nil,
                                              drynrun: nil,
                                              snapshot: snapshot).getArguments()
        let command = RsyncAsync(arguments: arguments,
                                 processtermination: processtermination)
        await command.executeProcess()
    }
}

struct RestoreFileRecord: Identifiable {
    let id = UUID()
    var filename: String = ""
}
