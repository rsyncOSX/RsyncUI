//
//  CommandandParameterTab.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 07/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct RsyncCommandView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @Binding var isPresented: Bool

    @State private var selectedrsynccommand = RsyncCommand.synchronize

    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false
    @State private var selecteduuids = Set<UUID>()

    var selectedconfig: Configuration?

    var body: some View {
        VStack {
            HStack {
                pickerselectcommand

                parameterlist
            }
            .padding()

            showcommand

            Spacer()

            HStack {
                Spacer()

                Button("Dismiss") { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .frame(maxWidth: 500, minHeight: 300)
        .padding()
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
            .padding()
            .border(Color.gray)
            .textSelection(.enabled)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }

    var parameterlist: some View {
        ParametersList(selectedconfig: selectedconfig)
    }

    var commandstring: String? {
        if let index = rsyncUIdata.configurations?.firstIndex(where: { $0.hiddenID == selectedconfig?.hiddenID }) {
            if let config = selectedconfig {
                return RsyncCommandtoDisplay(index: index,
                                             display: selectedrsynccommand,
                                             config: config).getrsyncommand()
            }
        }
        return "Select a configuration"
    }

    func dismissview() {
        isPresented = false
    }
}
