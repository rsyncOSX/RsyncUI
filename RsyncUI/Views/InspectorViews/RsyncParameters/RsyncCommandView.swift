//
//  RsyncCommandView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/01/2021.
//

import SwiftUI

struct RsyncCommandView: View {
    @State var selectedrsynccommand: RsyncCommand = .synchronizeData

    let config: SynchronizeConfiguration

    var body: some View {
        VStack(alignment: .leading) {
            Picker("", selection: $selectedrsynccommand) {
                ForEach(RsyncCommand.allCases) { Text($0.description)
                    .tag($0)
                }
            }
            .pickerStyle(RadioGroupPickerStyle())
            .padding(10)

            showcommand
        }
        .padding(10)
    }

    var showcommand: some View {
        Text(commandstring ?? "")
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

    var commandstring: String? {
        RsyncCommandtoDisplay(display: selectedrsynccommand,
                              config: config).rsynccommand
    }
}
