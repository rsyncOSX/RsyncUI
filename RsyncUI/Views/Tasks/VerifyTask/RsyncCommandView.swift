//
//  RsyncCommandView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/01/2021.
//

import SwiftUI

struct RsyncCommandView: View {
    @State var selectedrsynccommand: RsyncCommand = .synchronizeData
    @State private var otherselectedrsynccommand = OtherRsyncCommand.listRemoteFiles

    let config: SynchronizeConfiguration

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Picker("", selection: $selectedrsynccommand) {
                    ForEach(RsyncCommand.allCases) { Text($0.description)
                        .tag($0)
                    }
                }
                .pickerStyle(RadioGroupPickerStyle())
                .padding(10)

                Picker("", selection: $otherselectedrsynccommand) {
                    ForEach(OtherRsyncCommand.allCases) { Text($0.description)
                        .tag($0)
                    }
                }
                .pickerStyle(RadioGroupPickerStyle())
                .padding(10)
            }

            VStack(alignment: .leading) {
                showcommandrsync
                    .padding(10)
                showcommandother
                    .padding(10)
            }
        }
        .padding(10)
    }

    var showcommandrsync: some View {
        Text(commandstringrsync ?? "")
            .textSelection(.enabled)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity)
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.blue, lineWidth: 1)
            )
    }

    var commandstringrsync: String? {
        RsyncCommandtoDisplay(display: selectedrsynccommand,
                              config: config).rsynccommand
    }

    var showcommandother: some View {
        Text(commandstringother)
            .textSelection(.enabled)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity)
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.blue, lineWidth: 1)
            )
    }

    var commandstringother: String {
        OtherRsyncCommandtoDisplay(display: otherselectedrsynccommand,
                                   config: config).command
    }
}
