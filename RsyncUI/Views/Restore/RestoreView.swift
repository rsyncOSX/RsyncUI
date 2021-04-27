//
//  RestoreView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/04/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct RestoreView: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @StateObject var restoresettings = ObserveableReferenceRestore()

    @State private var presentsheetview = false
    @State private var output: [String]?

    // Not used but requiered in parameter
    @State private var selecteduuids = Set<UUID>()
    @State private var inwork = -1
    @State private var selectable = false

    var body: some View {
        ZStack {
            VStack {
                SearchbarView(text: $restoresettings.filterstring.onChange {
                    restoresettings.inputchangedbyuser = true
                })
                    .padding(.top, -20)

                ConfigurationsList(selectedconfig: $restoresettings.selectedconfig.onChange {
                    restoresettings.filestorestore = ""
                },
                selecteduuids: $selecteduuids,
                inwork: $inwork,
                selectable: $selectable)
            }

            if restoresettings.gettingfilelist == true {
                RotatingDotsIndicatorView()
                    .frame(width: 50.0, height: 50.0)
                    .foregroundColor(.red)
            }
        }

        Spacer()

        HStack {
            Spacer()

            ToggleView(NSLocalizedString("--dry-run", comment: "RestoreView"), $restoresettings.dryrun)

            VStack(alignment: .leading) {
                numberoffiles

                setfilestorestore

                setpathforrestore
            }

            Spacer()

            Button(NSLocalizedString("View", comment: "RestoreView")) { presentoutput() }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $presentsheetview) { viewoutput }

            Button(NSLocalizedString("Restore", comment: "RestoreView")) { restore() }
                .buttonStyle(AbortButtonStyle())

            Button(NSLocalizedString("Abort", comment: "RestoreView")) { abort() }
                .buttonStyle(AbortButtonStyle())
        }
    }

    var setpathforrestore: some View {
        EditValue(500, NSLocalizedString("Path for restore", comment: "RestoreView"), $restoresettings.pathforrestore.onChange {
            restoresettings.inputchangedbyuser = true
        })
            .onAppear(perform: {
                if let pathforrestore = SharedReference.shared.pathforrestore {
                    restoresettings.pathforrestore = pathforrestore
                }
            })
    }

    var setfilestorestore: some View {
        EditValue(500, NSLocalizedString("Select files to restore or \"./.\" for full restore", comment: "RestoreView"), $restoresettings.filestorestore.onChange {
            restoresettings.inputchangedbyuser = true
        })
    }

    var numberoffiles: some View {
        HStack {
            Text(NSLocalizedString("Number of files", comment: "RestoreView") + ": ")
            Text(NumberFormatter.localizedString(from: NSNumber(value: restoresettings.numberoffiles), number: NumberFormatter.Style.decimal))
                .foregroundColor(Color.blue)

            Spacer()
        }
        .frame(width: 300)
    }

    // Output
    var viewoutput: some View {
        OutputRsyncView(isPresented: $presentsheetview,
                        output: $output,
                        valueselectedrow: $restoresettings.filestorestorefromview)
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
            restoresettings.outputprocess = nil
            restoresettings.numberoffiles = 0
            return
        }
        output = restoresettings.getoutput()
        presentsheetview = true
    }

    func restore() {
        if let config = restoresettings.selectedconfig {
            restoresettings.restore(config)
        }
    }
}
