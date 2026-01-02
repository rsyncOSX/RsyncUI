//
//  OtherRsyncCommandsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 16/09/2024.
//

import SwiftUI

struct OtherRsyncCommandsView: View {
    @Binding var otherselectedrsynccommand: OtherRsyncCommand

    let config: SynchronizeConfiguration

    var body: some View {
        HStack {
            pickerselectcommand
            showcommand
        }
    }

    var pickerselectcommand: some View {
        Picker("", selection: $otherselectedrsynccommand) {
            ForEach(OtherRsyncCommand.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(RadioGroupPickerStyle())
    }

    var showcommand: some View {
        Text(commandstring)
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

    var commandstring: String {
        OtherRsyncCommandtoDisplay(display: otherselectedrsynccommand,
                                   config: config).command
    }
}
