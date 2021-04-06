//
//  RestoreView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/04/2021.
//

import SwiftUI

enum TypeofRestore: String, CaseIterable, Identifiable, CustomStringConvertible {
    case fullrestore
    case restorebyfiles

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
        ConfigurationsList(selectedconfig: $selectedconfig.onChange {},
                           selecteduuids: $selecteduuids,
                           inwork: $inwork,
                           selectable: $selectable)

        Spacer()

        HStack {
            Spacer()

            Button(NSLocalizedString("Restore", comment: "Delete")) {}
                .buttonStyle(AbortButtonStyle())

            Button(NSLocalizedString("Abort", comment: "Abort button")) { abort() }
                .buttonStyle(AbortButtonStyle())
        }
    }
}

extension RestoreView {
    func abort() {}
}
