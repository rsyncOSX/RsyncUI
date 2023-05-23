//
//  RestoreView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/04/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct RestoreView: View {
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

            Spacer()

            if restore.selectedconfig != nil { showcommand }
        }

        HStack {
            Button("Files") {
                guard SharedReference.shared.process == nil else { return }
                guard restore.selectedconfig != nil else { return }
                presentsheetviewfiles = true
            }
            .buttonStyle(PrimaryButtonStyle())
            .sheet(isPresented: $presentsheetviewfiles) { viewoutputfiles }

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

    // Output select files tpo restore
    var viewoutputfiles: some View {
        RestoreFilesView(isPresented: $presentsheetviewfiles,
                         selectrowforrestore: $restore.selectedrowforrestore,
                         config: $restore.selectedconfig,
                         filterstring: $filterstring)
    }

    // Output from rsync
    var viewoutput: some View {
        OutputRsyncView(output: restore.rsyncdata ?? [])
    }
}

extension RestoreView {
    func abort() {
        _ = InterruptProcess()
    }
}

// swiftlint:enable line_length
