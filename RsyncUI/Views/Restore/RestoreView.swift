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
    @StateObject var restore = ObserveableRestore()
    @State private var presentsheetview = false

    var body: some View {
        ZStack {
            VStack {
                ListofAllTasks(selectedconfig: $restore.selectedconfig)
            }
        }

        Spacer()

        HStack {
            Button("Files") {
                guard SharedReference.shared.process == nil else { return }
                guard restore.selectedconfig != nil else { return }
                presentsheetview = true
            }
            .buttonStyle(PrimaryButtonStyle())
            .sheet(isPresented: $presentsheetview) { viewoutput }

            Spacer()

            ZStack {
                VStack(alignment: .leading) {
                    // numberoffiles

                    setfilestorestore

                    setpathforrestore
                }
            }

            if restore.restorefilesinprogress == true {
                ZStack {
                    ProgressView()
                        .frame(width: 50.0, height: 50.0)
                }
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

            Button("Abort") { abort() }
                .buttonStyle(AbortButtonStyle())
        }
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

    // Output
    var viewoutput: some View {
        RestoreFilesView(isPresented: $presentsheetview,
                         selectrowforrestore: $restore.selectedrowforrestore,
                         config: $restore.selectedconfig)
    }
}

extension RestoreView {
    func abort() {
        _ = InterruptProcess()
    }

    func presentoutput() {
        // Check that files are not been collected
        guard SharedReference.shared.process == nil else { return }
        guard restore.selectedconfig != nil else { return }
        presentsheetview = true
    }
}
