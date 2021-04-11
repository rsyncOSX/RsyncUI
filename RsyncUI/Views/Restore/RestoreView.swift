//
//  RestoreView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/04/2021.
//
// swiftlint:disable line_length

import SwiftUI
import SwiftyBeaver

enum TypeofRestore: String, CaseIterable, Identifiable, CustomStringConvertible {
    case fullrestore = "Full restore"
    case byfile = "By file"

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

struct RestoreView: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @StateObject var restoresettings = ObserveableReferenceRestore()

    @State private var presentsheetview = false
    @State private var output: [Outputrecord]?

    // Not used but requiered in parameter
    @State private var selecteduuids = Set<UUID>()
    @State private var inwork = -1
    @State private var selectable = false

    let log = SwiftyBeaver.self

    var body: some View {
        ZStack {
            VStack {
                SearchbarView(text: $restoresettings.filterstring)
                    .padding(.top, -20)
                ConfigurationsList(selectedconfig: $restoresettings.selectedconfig,
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
            VStack(alignment: .leading) {
                setpathforrestore

                setfilestorestore
            }

            VStack(alignment: .leading) {
                pickerselecttypeofrestore

                numberoffiles
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
        EditValue(250, NSLocalizedString("Path for restore", comment: "RestoreView"), $restoresettings.restorepath)
            .onAppear(perform: {
                if let pathforrestore = SharedReference.shared.pathforrestore {
                    restoresettings.restorepath = pathforrestore
                }
            })
    }

    var setfilestorestore: some View {
        EditValue(250, NSLocalizedString("Select files to restore", comment: "RestoreView"), $restoresettings.filestorestore)
    }

    var numberoffiles: some View {
        HStack {
            Text(NSLocalizedString("Number of files", comment: "RestoreView") + ": ")
            Text(NumberFormatter.localizedString(from: NSNumber(value: restoresettings.numberoffiles), number: NumberFormatter.Style.decimal))
                .foregroundColor(Color.blue)
        }
    }

    // Output
    var viewoutput: some View {
        OutputRsyncView(isPresented: $presentsheetview,
                        output: $output)
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
        // Output from realrun
        let start = CFAbsoluteTimeGetCurrent()
        output = restoresettings.getoutput()
        let diff = CFAbsoluteTimeGetCurrent() - start
        log.info("presentoutput(): \(diff) seconds")
        log.info("number of lines: \(output?.count ?? 0)")
        presentsheetview = true
    }

    func restore() {
        _ = NotYetImplemented()
    }
}
