//
//  RestoreTableView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 05/06/2023.
//

import SwiftUI

struct RestoreTableView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @Binding var filterstring: String
    @StateObject var restore = ObserveableRestore()
    @State private var selecteduuids = Set<Configuration.ID>()
    @State private var presentsheetviewfiles = false

    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var reload: Bool = false
    @State private var confirmdelete: Bool = false

    var body: some View {
        VStack {
            TabView {
                ListofTasksView(
                    selecteduuids: $selecteduuids.onChange {
                        restore.filestorestore = ""
                        restore.commandstring = ""
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
                    },
                    inwork: $inwork,
                    filterstring: $filterstring,
                    reload: $reload,
                    confirmdelete: $confirmdelete
                )
                .tabItem {
                    Label("Tasks", systemImage: "gear")
                }

                RestoreFilesTableView(config: restore.selectedconfig)
                    .tabItem {
                        Label("Files", systemImage: "gear")
                    }
            }

            Spacer()

            if restore.selectedconfig != nil { showcommand }
        }

        HStack {
            Spacer()

            ZStack {
                VStack(alignment: .leading) {
                    setfilestorestore

                    setpathforrestore
                }

                if restore.restorefilesinprogress == true { ProgressView() }
            }

            Spacer()

            ToggleViewDefault("--dry-run", $restore.dryrun)

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
}

// swiftlint:enable line_length
