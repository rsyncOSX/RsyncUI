//
//  RestoreView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/04/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct RestoreView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @StateObject var restoresettings = ObserveableRestore()

    @State private var presentsheetview = false
    @State private var filterstring = ""
    // Not used but requiered in parameter
    @State private var selecteduuids = Set<UUID>()
    @State private var inwork = -1
    @State private var searchText: String = ""

    let selectable = false

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
                searchText: $searchText,
                selectable: selectable)
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

            ToggleView("--dry-run", $restoresettings.dryrun)

            VStack(alignment: .leading) {
                numberoffiles

                setfilestorestore

                setpathforrestore
            }

            Spacer()

            Button("View") { presentoutput() }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $presentsheetview) { viewoutput }

            Button("Restore") { restore() }
                .buttonStyle(AbortButtonStyle())

            Button("Abort") { abort() }
                .buttonStyle(AbortButtonStyle())
        }
        .searchable(text: $filterstring.onChange {
            restoresettings.inputchangedbyuser = true
            print("filer")
        })

        /*
         TODO: search does not work
         */
    }

    var setpathforrestore: some View {
        EditValue(500, "Path for restore", $restoresettings.pathforrestore.onChange {
            restoresettings.inputchangedbyuser = true
        })
            .onAppear(perform: {
                if let pathforrestore = SharedReference.shared.pathforrestore {
                    restoresettings.pathforrestore = pathforrestore
                }
            })
    }

    var setfilestorestore: some View {
        EditValue(500, "Select files to restore or \"./.\" for full restore", $restoresettings.filestorestore.onChange {
            restoresettings.inputchangedbyuser = true
        })
    }

    var numberoffiles: some View {
        HStack {
            Text("Number of files" + ": ")
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
            restoresettings.outputprocess = nil
            restoresettings.numberoffiles = 0
            return
        }
        presentsheetview = true
    }

    func restore() {
        if let config = restoresettings.selectedconfig {
            restoresettings.restore(config)
        }
    }
}
