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
    @StateObject var restoresettings = ObserveableRestore()

    @State private var presentsheetview = false
    @State private var filterstring = ""

    let selectable = false

    var body: some View {
        ZStack {
            VStack {
                ConfigurationsListNoSearch(selectedconfig: $restoresettings.selectedconfig.onChange {
                    restoresettings.filestorestore = ""
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

                if restoresettings.gettingfilelist == true {
                    ZStack {
                        RotatingDotsIndicatorView()
                            .frame(width: 50.0, height: 50.0)
                            .foregroundColor(.red)

                        Text("\(restoresettings.numberoffilesrestored)")
                    }
                }
            }

            Spacer()

            ToggleViewDefault("--dry-run", $restoresettings.dryrun)

            Button("Restore") {
                Task {
                    await restore()
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("Abort") { abort() }
                .buttonStyle(AbortButtonStyle())
        }
        .searchable(text: $restoresettings.filterstring.onChange {
            restoresettings.inputchangedbyuser = true
        })
    }

    var setpathforrestore: some View {
        EditValue(500, NSLocalizedString("Path for restore", comment: ""), $restoresettings.pathforrestore.onChange {
            restoresettings.inputchangedbyuser = true
        })
        .onAppear(perform: {
            if let pathforrestore = SharedReference.shared.pathforrestore {
                restoresettings.pathforrestore = pathforrestore
            }
        })
    }

    var setfilestorestore: some View {
        EditValue(500, NSLocalizedString("Select files to restore or \"./.\" for full restore", comment: ""), $restoresettings.filestorestore.onChange {
            restoresettings.inputchangedbyuser = true
        })
    }

    var numberoffiles: some View {
        HStack {
            Text(NSLocalizedString("Number of files", comment: "") + ": ")
            Text(NumberFormatter.localizedString(from: NSNumber(value: restoresettings.numberoffiles), number: NumberFormatter.Style.decimal))
                .foregroundColor(Color.blue)

            Spacer()
        }
        .frame(width: 300)
    }

    // Output
    var viewoutput: some View {
        OutputRsyncView(isPresented: $presentsheetview,
                        valueselectedrow: $restoresettings.filestorestorefromview,
                        numberoffiles: $restoresettings.numberoffiles,
                        output: restoresettings.getoutput() ?? [])
    }
}

extension RestoreView {
    func abort() {
        _ = InterruptProcess()
    }

    func presentoutput() {
        // Check that files are not been collected
        guard SharedReference.shared.process == nil else { return }
        guard restoresettings.selectedconfig != nil else {
            restoresettings.numberoffiles = 0
            return
        }
        presentsheetview = true
    }

    func restore() async {
        if let config = restoresettings.selectedconfig {
            await restoresettings.restore(config)
        }
    }
}
