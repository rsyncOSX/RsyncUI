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
    @Binding var selectedconfig: Configuration?

    // Not used but requiered in parameter
    @State private var selecteduuids = Set<UUID>()
    @State private var inwork = -1
    @State private var selectable = false

    var body: some View {
        SearchbarView(text: $restoresettings.filterstring)
            .padding(.top, -20)
        ConfigurationsList(selectedconfig: $selectedconfig.onChange {},
                           selecteduuids: $selecteduuids,
                           inwork: $inwork,
                           selectable: $selectable)

        Spacer()

        HStack {
            pickerselecttypeofrestore

            setpathforrestore

            Spacer()

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
}

extension RestoreView {
    func abort() {}
}
