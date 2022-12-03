//
//  CommandandParameterTab.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 07/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct RsyncCommandView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @Binding var config: Configuration?

    @State private var selectedrsynccommand = RsyncCommand.synchronize
    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false
    @State private var selecteduuids = Set<UUID>()

    var body: some View {
        HStack {
            pickerselectcommand

            showcommand
        }
    }

    var pickerselectcommand: some View {
        Picker("", selection: $selectedrsynccommand) {
            ForEach(RsyncCommand.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(RadioGroupPickerStyle())
    }

    var showcommand: some View {
        Text(commandstring ?? "")
            .textSelection(.enabled)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity)
    }

    var commandstring: String? {
        if let config = config {
            return RsyncCommandtoDisplay(display: selectedrsynccommand,
                                         config: config).getrsyncommand()
        } else {
            return NSLocalizedString("Select a configuration", comment: "")
        }
    }
}
