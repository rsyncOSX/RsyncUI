//
//  RestoreTableView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 05/06/2023.
//

import SwiftUI

struct RestoreTableView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @StateObject var restore = ObserveableRestore()
    @State private var selecteduuids = Set<Configuration.ID>()
    @State private var filestorestore: String = ""

    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var reload: Bool = false
    @State private var confirmdelete: Bool = false
    @State private var showrestorecommand: Bool = false
    @State private var gettingfilelist: Bool = false

    var body: some View {
        VStack {
            TabView {
                ListofTasksLightView(
                    selecteduuids: $selecteduuids.onChange {
                        restore.selectedrowforrestore = ""
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
                        }
                    }
                )
                .tabItem {
                    Text("Restore from")
                }

                RestoreFilesTableView(filestorestore: $filestorestore.onChange {
                    restore.selectedrowforrestore = filestorestore
                },
                config: restore.selectedconfig, datalist: restore.datalist)
                    .tabItem {
                        Text("List of files")
                    }
            }

            Spacer()

            ZStack {
                if showrestorecommand { showcommand }
                if gettingfilelist { ProgressView() }
                if restore.restorefilesinprogress { ProgressView() }
            }
        }

        HStack {
            Spacer()

            VStack(alignment: .leading) {
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
                    if let config = restore.selectedconfig {
                        guard config.task != SharedReference.shared.syncremote else { return }
                        gettingfilelist = true
                        await getfilelist(config)
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("Restore") {
                Task {
                    if let config = restore.selectedconfig {
                        await restore.restore(config)
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("Log") {
                guard SharedReference.shared.process == nil else { return }
                guard restore.selectedconfig != nil else { return }
                restore.presentsheetrsync = true
            }
            .buttonStyle(PrimaryButtonStyle())
            .sheet(isPresented: $restore.presentsheetrsync) { viewoutput }

            Button("Abort") { abort() }
                .buttonStyle(AbortButtonStyle())
        }
        .sheet(isPresented: $restore.presentsheetrsync) { viewoutput }
    }

    var showcommand: some View {
        Text(restore.commandstring)
            .textSelection(.enabled)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity)
    }

    var setpathforrestore: some View {
        EditValue(500, NSLocalizedString("Path for restore", comment: ""), $restore.pathforrestore.onChange {
            restore.inputchangedbyuser = true
        })
        .onAppear(perform: {
            if let pathforrestore = SharedReference.shared.pathforrestore {
                restore.pathforrestore = pathforrestore
            }
        })
    }

    var setfilestorestore: some View {
        EditValue(500, NSLocalizedString("Select files to restore or \"./.\" for full restore", comment: ""), $restore.filestorestore.onChange {
            restore.inputchangedbyuser = true
        })
    }

    var numberoffiles: some View {
        HStack {
            Text(NSLocalizedString("Number of files", comment: "") + ": ")
            Text(NumberFormatter.localizedString(from: NSNumber(value: restore.numberoffiles), number: NumberFormatter.Style.decimal))
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

    // let data = TrimOne(datalist).trimmeddata.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }
    func processtermination(data: [String]?) {
        gettingfilelist = false
        restore.datalist = TrimOne(data ?? []).trimmeddata.map { filename in
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

// swiftlint:enable line_length
