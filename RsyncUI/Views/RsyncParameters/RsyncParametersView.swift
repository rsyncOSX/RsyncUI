//
//  RsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/03/2021.
//

import SwiftUI

struct RsyncParametersView: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @Binding var reload: Bool
    @Binding var updated: Bool
    @Binding var showdetails: Bool
    @Binding var selectedconfig: Configuration?
    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false
    @State private var selecteduuids = Set<UUID>()

    var body: some View {
        ConfigurationsList(selectedconfig: $selectedconfig.onChange { opendetails() },
                           selecteduuids: $selecteduuids,
                           inwork: $inwork,
                           selectable: $selectable)

        if updated == true { notifyupdated }
    }

    var notifyupdated: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text(NSLocalizedString("Updated", comment: "settings"))
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 120, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
    }

    func opendetails() {
        if selectedconfig != nil {
            showdetails = true
        }
    }
}
