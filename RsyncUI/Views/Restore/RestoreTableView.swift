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

    var body: some View {
        VStack {
            ZStack {
                HStack {
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

                    RestoreFilesTableView(filestorestore: $filestorestore.onChange {
                        restore.selectedrowforrestore = filestorestore
                    })
                    .environmentObject(restore)
                }

                if nosearcstringalert { nosearchstring }
            }

            Spacer()

            ZStack {
                if showrestorecommand { showcommand }
                if gettingfilelist { AlertToast(displayMode: .alert, type: .loading) }
                if restore.restorefilesinprogress { AlertToast(displayMode: .alert, type: .loading) }
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
                    guard filterstring.count > 0 else {
                        nosearcstringalert = true
                        return
                    }
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

    var nosearchstring: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text("Please add a search string")
                .font(.title3)
                .foregroundColor(Color.accentColor)
        }
        .frame(width: 220, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
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

    var setfilter: some View {
        EditValue(500, NSLocalizedString("Filter to search remote data", comment: ""), $filterstring)
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

// swiftlint:enable line_length
