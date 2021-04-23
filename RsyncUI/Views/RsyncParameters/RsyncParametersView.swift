//
//  RsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/03/2021.
//
// swiftlint:disable line_length cyclomatic_complexity

import SwiftUI

struct RsyncParametersView: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @Binding var reload: Bool
    @Binding var updated: Bool
    @Binding var showdetails: Bool

    @StateObject private var parameters = ObserveableParametersRsync()

    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false
    @State private var selecteduuids = Set<UUID>()
    // Show updated
    @State private var selectedrsynccommand = RsyncCommand.synchronize
    @State private var presentrsynccommandoview = false

    var body: some View {
        ConfigurationsList(selectedconfig: $parameters.configuration.onChange { showdetails = true },
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
}
