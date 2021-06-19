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
    @Binding var selectedconfig: Configuration?
    @Binding var isPresented: Bool

    @State private var selectedrsynccommand = RsyncCommand.synchronize

    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false
    @State private var selecteduuids = Set<UUID>()

    var body: some View {
        headingtitle

        VStack {
            pickerselectcommand

            showcommand

            parameterlist

            Spacer()

            HStack {
                Spacer()

                Button(NSLocalizedString("Copy", comment: "Copy button")) { copytopasteboard() }
                    .buttonStyle(PrimaryButtonStyle())

                Button(NSLocalizedString("Dismiss", comment: "Dismiss button")) { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .frame(width: 600, height: 300)
        .padding()
    }

    var pickerselectcommand: some View {
        Picker(NSLocalizedString("Command", comment: "CommandTab") + ":",
               selection: $selectedrsynccommand) {
            ForEach(RsyncCommand.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .frame(width: 300)
    }

    var headingtitle: some View {
        Text(NSLocalizedString("Rsync command and parameters", comment: "RsyncCommandView"))
            .font(.title2)
            .padding()
    }

    var showcommand: some View {
        Text(commandstring ?? "")
            .padding()
            .border(Color.gray)
    }

    var parameterlist: some View {
        ParametersList(selectedconfig: $selectedconfig)
    }

    var commandstring: String? {
        if let index = rsyncUIdata.configurations?.firstIndex(where: { $0.hiddenID == selectedconfig?.hiddenID }) {
            if let config = selectedconfig {
                return RsyncCommandtoDisplay(index: index,
                                             display: selectedrsynccommand,
                                             config: config).getrsyncommand()
            }
        }
        return NSLocalizedString("Select a configuration", comment: "RsyncCommandView") + "..."
    }

    func dismissview() {
        isPresented = false
    }

    func copytopasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(commandstring ?? "", forType: .string)
    }
}
