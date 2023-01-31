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
    @State private var filterstring = ""

    // Focus buttons from the menu
    @State private var focusaborttask: Bool = false

    let selectable = false

    var body: some View {
        ZStack {
            VStack {
                ConfigurationsListNoSearch(selectedconfig: $restore.selectedconfig.onChange {
                    restore.filestorestore = ""
                })
            }
        }

        Spacer()

        HStack {
            Button("Files") { presentoutput() }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $presentsheetview) { viewoutput }

            Spacer()

            ZStack {
                VStack(alignment: .leading) {
                    numberoffiles

                    setfilestorestore

                    setpathforrestore
                }

                if restore.gettingfilelist == true {
                    ZStack {
                        RotatingDotsIndicatorView()
                            .frame(width: 50.0, height: 50.0)
                            .foregroundColor(.blue)

                        Text("\(restore.numberoffilesrestored)")
                    }
                }

                if focusaborttask { labelaborttask }
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
        .searchable(text: $restore.filterstring.onChange {
            restore.inputchangedbyuser = true
        })
        .focusedSceneValue(\.aborttask, $focusaborttask)
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
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
        OutputRsyncView(isPresented: $presentsheetview,
                        valueselectedrow: $restore.filestorestorefromview,
                        numberoffiles: $restore.numberoffiles,
                        output: restore.getoutput() ?? [])
    }
}

extension RestoreView {
    func abort() {
        _ = InterruptProcess()
    }

    func presentoutput() {
        // Check that files are not been collected
        guard SharedReference.shared.process == nil else { return }
        guard restore.selectedconfig != nil else {
            restore.numberoffiles = 0
            return
        }
        presentsheetview = true
    }
}
