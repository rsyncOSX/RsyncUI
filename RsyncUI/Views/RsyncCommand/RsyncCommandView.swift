//
//  CommandandParameterTab.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 07/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct RsyncCommandView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @State private var selectedconfig: Configuration?
    @State private var selectedrsynccommand = RsyncCommand.synchronize

    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false
    @State private var selecteduuids = Set<UUID>()

    var body: some View {
        ConfigurationsList(selectedconfig: $selectedconfig.onChange { rsyncOSXData.update() },
                           selecteduuids: $selecteduuids,
                           inwork: $inwork,
                           selectable: $selectable)

        Spacer()

        ScrollView {
            HStack {
                if selectedconfig != nil { command }

                if selectedconfig != nil { parameterlist }
            }
        }

        HStack {
            Spacer()

            Picker(NSLocalizedString("Command", comment: "CommandTab") + ":",
                   selection: $selectedrsynccommand) {
                ForEach(RsyncCommand.allCases) { Text($0.description)
                    .tag($0)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 300)

            Spacer()

            Button(NSLocalizedString("Copy", comment: "Copy button")) { copytopasteboard() }
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    var command: some View {
        Text(commandstring ?? "")
            .padding(10)
            .border(Color.gray)
    }

    var parameterlist: some View {
        ParametersList(selectedconfig: $selectedconfig)
    }

    var commandstring: String? {
        if let index = rsyncOSXData.configurations?.firstIndex(where: { $0.hiddenID == selectedconfig?.hiddenID }) {
            return RsyncCommandtoDisplay(index: index,
                                         display: selectedrsynccommand,
                                         allarguments: rsyncOSXData.arguments).getrsyncommand()
        }
        return nil
    }

    func copytopasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(commandstring ?? "", forType: .string)
    }
}
