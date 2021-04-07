//
//  RestoreView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/04/2021.
//

import SwiftUI

enum TypeofRestore: String, CaseIterable, Identifiable, CustomStringConvertible {
    case fullrestore
    case byfile

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

struct RestoreView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @StateObject var restoresettings = ObserveableReferenceRestore()

    @State private var presentsheetview = false
    @State private var output: [Outputrecord]?

    // Not used but requiered in parameter
    @State private var selecteduuids = Set<UUID>()
    @State private var inwork = -1
    @State private var selectable = false

    var body: some View {
        VStack {
            SearchbarView(text: $restoresettings.filterstring)
                .padding(.top, -20)
            ConfigurationsList(selectedconfig: $restoresettings.selectedconfig.onChange {},
                               selecteduuids: $selecteduuids,
                               inwork: $inwork,
                               selectable: $selectable)
        }

        if restoresettings.gettingfilelist == true {
            RotatingDotsIndicatorView()
                .frame(width: 50.0, height: 50.0)
                .foregroundColor(.red)
        }

        Spacer()

        HStack {
            pickerselecttypeofrestore

            setpathforrestore

            Spacer()

            Button(NSLocalizedString("View", comment: "View button")) { presentoutput() }
                .buttonStyle(PrimaryButtonStyle())
                .sheet(isPresented: $presentsheetview) { viewoutput }

            Button(NSLocalizedString("Restore", comment: "Delete")) {}
                .buttonStyle(AbortButtonStyle())

            Button(NSLocalizedString("Abort", comment: "Abort button")) { abort() }
                .buttonStyle(AbortButtonStyle())
        }
    }

    var pickerselecttypeofrestore: some View {
        Picker(NSLocalizedString("Restore", comment: "RestoreView") + ":",
               selection: $restoresettings.typeofrestore) {
            ForEach(TypeofRestore.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 180)
    }

    var setpathforrestore: some View {
        EditValue(250, NSLocalizedString("Path for restore", comment: "settings"), $restoresettings.restorepath)
            .onAppear(perform: {
                if let pathforrestore = SharedReference.shared.pathforrestore {
                    restoresettings.restorepath = pathforrestore
                }
            })
    }

    // Output
    var viewoutput: some View {
        OutputRsyncView(isPresented: $presentsheetview,
                        output: $output)
    }
}

extension RestoreView {
    func abort() {}

    func presentoutput() {
        // Output from realrun
        output = restoresettings.getoutput()
        presentsheetview = true
    }
}
